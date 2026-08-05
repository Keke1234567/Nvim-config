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

local function lm_studio_url()
  return ("http://%s:1234"):format(require("util.wsl_host").ip())
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
          -- ...except plugin UIs. auto_trigger_ft = "*" makes minuet's own
          -- FileType autocmd set the trigger flag on *every* buffer, including
          -- prompt/scratch buffers. The global toggle below can't undo that:
          -- it only touches `buftype == ""` buffers, and these are "prompt"/
          -- "nofile". Result was a completion request per keystroke in the
          -- Telescope prompt ("Request failed with exit code 7" when LM Studio
          -- is down, plus a stall while curl is spawned). Ignore them here —
          -- there's nothing to infill in a picker query anyway.
          auto_trigger_ignore_ft = {
            "TelescopePrompt",
            "TelescopeResults",
            "neo-tree",
            "neo-tree-popup",
            "harpoon",
            "dap-repl",
            "dapui_watches",
            "dapui_hover",
            "lazy",
            "mason",
            "checkhealth",
            "help",
            "qf",
          },
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

      -- Global on/off state. minuet's own toggle is buffer-local
      -- (`vim.b.minuet_virtual_text_auto_trigger`), which means flipping it
      -- off in one file leaves it on in the next buffer you open. That's
      -- annoying for a "shut up" switch — track intent globally and enforce
      -- it on every current and future buffer. Off by default; <F2> arms it.
      vim.g.minuet_enabled = false

      local function apply_minuet_state()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" then
            vim.b[buf].minuet_virtual_text_auto_trigger = vim.g.minuet_enabled
          end
        end
        if not vim.g.minuet_enabled then
          -- Kill any suggestion currently painted so the user isn't stuck
          -- staring at ghost text after flipping off.
          pcall(require("minuet.virtualtext").action.dismiss)
        end
      end

      -- Arm the flag on every buffer that gets opened later. FileType is in
      -- the list because minuet's own FileType autocmd (auto_trigger_ft =
      -- "*") unconditionally sets the flag true; ours is registered after
      -- minuet's setup() so it runs second on the same event and wins.
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "FileType" }, {
        callback = function(args)
          if vim.bo[args.buf].buftype == "" then
            vim.b[args.buf].minuet_virtual_text_auto_trigger = vim.g.minuet_enabled
          end
        end,
      })

      apply_minuet_state()

      local function toggle_minuet()
        vim.g.minuet_enabled = not vim.g.minuet_enabled
        apply_minuet_state()
        vim.notify("Minuet AI " .. (vim.g.minuet_enabled and "ON" or "OFF"),
          vim.log.levels.INFO)
      end

      vim.api.nvim_create_user_command("MinuetToggle", toggle_minuet, {})
      vim.keymap.set({ "n", "i" }, "<F2>", toggle_minuet,
        { silent = true, desc = "Toggle minuet AI suggestions" })

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
