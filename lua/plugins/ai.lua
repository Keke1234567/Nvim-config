-- AI / LLM plugins.
--
-- Local autocomplete via LM Studio (running natively on Windows, RX 9070 XT).
-- Neovim runs in WSL (mirrored networking). The WSL→host loopback path
-- (hostAddressLoopback) never worked here, so we reach LM Studio over the
-- Windows host's LAN IP instead. Requirements:
--   * LM Studio: "Serve on Local Network" enabled (binds 0.0.0.0:1234).
--   * C:\Users\keke\.wslconfig: [wsl2] networkingMode=mirrored, firewall=false
--     (applied via a full `wsl --shutdown` — policy binds at VM start).
-- Mirrored networking mirrors the host's LAN into WSL, so our own primary
-- LAN IPv4 *is* the host's address. Resolved dynamically below so a DHCP
-- lease change doesn't silently break completion.
--
-- Completion uses minuet's FIM provider against LM Studio's /v1/completions
-- endpoint with a FIM-capable *base* coder model (qwen/qwen2.5-coder-14b).
-- FIM = raw prefix/suffix infill, not a chat turn: no markdown code fences,
-- lower latency, better inline quality than the instruct chat model. The
-- old chat config is kept commented below as a fallback.
--
-- Ghost-text keymaps (insert mode):
--   <S-Tab>  accept full suggestion (inserts a literal Tab if none shown)
--   <A-Y>    accept one line
--   <A-]>    next suggestion
--   <A-[>    previous suggestion
--   <A-e>    dismiss

-- Primary LAN IPv4 of this machine = the mirrored Windows host IP that
-- LM Studio is reachable on. Prefer RFC1918 LAN ranges; skip loopback,
-- link-local, and (likely) docker bridges. Hardcoded fallback last.
-- Returns the scheme+host+port only; callers append the API path.
local function lm_studio_url()
  local uv = vim.uv or vim.loop
  local lan, any
  for _, addrs in pairs(uv.interface_addresses()) do
    for _, a in ipairs(addrs) do
      if a.family == "inet" and not a.internal
        and not a.ip:match("^169%.254%.") then
        any = any or a.ip
        if a.ip:match("^192%.168%.") or a.ip:match("^10%.") then
          lan = lan or a.ip
        end
      end
    end
  end
  local ip = lan or any or "192.168.50.187"
  return ("http://%s:1234"):format(ip)
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Must load before buffers' FileType events: minuet's auto-trigger flag
    -- is set by a FileType autocmd registered in setup(). InsertEnter would
    -- load it too late and no completions are ever requested.
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local host = lm_studio_url()

      require("minuet").setup({
        -- FIM via the /v1/completions endpoint. Structurally cannot emit
        -- markdown fences (it's text infill, not chat). To fall back to the
        -- instruct chat model, set this to "openai_compatible".
        provider = "openai_fim_compatible",

        -- One completion is enough for inline ghost text and keeps the
        -- local model snappy.
        n_completions = 1,

        -- Smaller context = lower latency on a local model. Bump if you want
        -- the model to "see" more of the file at the cost of speed.
        context_window = 2048,

        -- Local cold start can exceed the cloud-tuned default.
        request_timeout = 8,

        -- minuet disables this for FIM (default 0). The base coder model
        -- runs on past the infill and re-emits the post-cursor text, so
        -- re-enable it: trim a completion's tail when it byte-exactly
        -- duplicates >=N chars of the text after the cursor. Low (6) to
        -- aggressively catch "regenerated the rest of the file" dupes;
        -- raise if it starts clipping legit completions that happen to
        -- end like the following line.
        after_cursor_filter_length = 6,

        provider_options = {
          openai_fim_compatible = {
            -- LM Studio ignores the key value but minuet requires a
            -- non-empty one. `TERM` is always set in a terminal, so this
            -- avoids needing a dedicated env var.
            api_key = "TERM",
            name = "LMStudio",
            end_point = host .. "/v1/completions",
            -- Base (non-instruct) Qwen2.5-Coder; FIM-trained. Must match
            -- the model id shown in LM Studio's server/Developer tab.
            model = "qwen/qwen2.5-coder-14b",
            stream = true,
            optional = {
              max_tokens = 256,
              top_p = 0.9,
              -- A base (non-instruct) model won't stop on its own: it
              -- overruns the infill and re-emits surrounding code. "\n\n"
              -- keeps a suggestion to one coherent block; the rest are
              -- Qwen2.5-Coder FIM/EOG special tokens.
              stop = { "\n\n", "<|endoftext|>", "<|fim_pad|>", "<|file_sep|>", "<|repo_name|>" },
            },
          },

          -- Chat fallback (instruct model, /v1/chat/completions). Only used
          -- if `provider` above is switched to "openai_compatible". A 7B
          -- instruct model tends to wrap output in ```fences``` despite the
          -- prompt; the trim wrapper below scrubs them on this path.
          openai_compatible = {
            api_key = "TERM",
            name = "LMStudio",
            end_point = host .. "/v1/chat/completions",
            model = "qwen2.5-coder-7b-instruct",
            optional = {
              max_tokens = 256,
              top_p = 0.9,
            },
          },
        },

        virtualtext = {
          -- Copilot-style: auto-suggest in every filetype.
          auto_trigger_ft = { "*" },
          keymap = {
            -- accept is handled by the smart <S-Tab> map below (minuet's
            -- accept keymap has no no-suggestion fallback).
            accept_line = "<A-Y>",
            prev = "<A-[>",
            next = "<A-]>",
            dismiss = "<A-e>",
          },
        },
      })

      -- Guards the chat fallback only: an instruct model ignores minuet's
      -- "no markdown fences" guideline and wraps completions in ```lang ...
      -- ```. minuet only trims whitespace and has no response hook, so wrap
      -- its per-item trimmer to also peel a fence anchored at the start/end
      -- of the completion. Inert on the FIM path (raw infill has no fences,
      -- and FIM doesn't route through trim_completion_item anyway). Mid-text
      -- ``` (e.g. real Markdown) is left alone.
      local mu = require("minuet.utils")
      local orig_trim = mu.trim_completion_item
      mu.trim_completion_item = function(item, opts)
        item = orig_trim(item, opts)
        if not item then
          return item
        end
        item = item:gsub("^```[%w._+-]*\r?\n", "") -- opening ```lang\n
        item = item:gsub("^```[%w._+-]*$", "") --       opening fence alone
        item = item:gsub("\r?\n```%s*$", "") --          closing fence
        item = item:gsub("^```%s*$", "") --              closing fence alone
        return orig_trim(item, opts) -- re-trim blank lines a fence left behind
      end

      -- Buffers already open when minuet loads (or on :Lazy reload) missed
      -- the FileType autocmd that arms auto-trigger; enable it for them.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
          vim.b[buf].minuet_virtual_text_auto_trigger = true
        end
      end

      -- Smart <S-Tab>: accept the suggestion if one is shown, else a real Tab.
      vim.keymap.set("i", "<S-Tab>", function()
        local vt = require("minuet.virtualtext").action
        if vt.is_visible() then
          vt.accept()
        else
          vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { silent = true, desc = "minuet: accept suggestion or insert Tab" })
    end,
  },
}
