return {
  {
    "hrsh7th/nvim-cmp",
    config = function()
      local cmp = require("cmp") 

      -- Custom Ollama source
      local ollama_source = {}
      ollama_source.new = function()
        return setmetatable({}, { __index = ollama_source })
      end
      ollama_source.get_trigger_characters = function()
        return { ".", ":", " " }
      end
      ollama_source.complete = function(_, params, callback)
        local lines_before = table.concat(
          vim.api.nvim_buf_get_lines(0, 0, params.context.cursor.row, false),
          "\n"
        )
        local lines_after = table.concat(
          vim.api.nvim_buf_get_lines(0, params.context.cursor.row, -1, false),
          "\n"
        )
        local prompt = "<|fim_prefix|>" .. lines_before .. "<|fim_suffix|>" .. lines_after .. "<|fim_middle|>"

        vim.system({
          "curl", "-s", "http://127.0.0.1:11434/api/generate",
          "-d", vim.json.encode({
            model = "qwen2.5-coder:7b",
            prompt = prompt,
            stream = false,
            options = { temperature = 0.2, stop = { "<|endoftext|>" } },
          }),
        }, { text = true }, function(result)
          if result.code ~= 0 then return callback() end
          local ok, data = pcall(vim.json.decode, result.stdout)
          if not ok or not data.response then return callback() end
          callback({
            items = { { label = data.response, insertText = data.response } },
            isIncomplete = false,
          })
        end)
      end

      cmp.register_source("ollama", ollama_source.new())

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-e>"] = cmp.mapping.abort(),
        }),
        experimental = { ghost_text = true },
        sources = cmp.config.sources({
          { name = "ollama" },
        }),
      })
    end,
  },
}
