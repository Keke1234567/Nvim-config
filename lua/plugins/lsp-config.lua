return {
  {
    "williamboman/mason.nvim",
    opts = {},
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      -- lspconfig server names, not Mason package names
      ensure_installed = {
        "lua_ls",
        "ts_ls",
        "omnisharp",
      },
    },
    dependencies = {
      { "williamboman/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig"
    },
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" }
            }
          }
        }
      })

      vim.lsp.enable('tsserver', {
        cmd = {'typescript-language-server', '--stdio'},
        filetypes = { 'typescript' },
      })

      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "LSP Hover" })
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "LSP Go to Definition" })

      -- Diagnostics: read the full error in a proper float.
      vim.diagnostic.config({
        virtual_text = true,
        underline = true,
        severity_sort = true,
        float = { border = "rounded", source = true },
      })
      vim.keymap.set("n", "gl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })
      vim.keymap.set("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
      vim.keymap.set("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
    end,
    opts = {
      servers = {
        omnisharp = {
          handlers = {
            ["textDocument/definition"] = function(...)
              return require("omnisharp_extended").handler(...)
            end,
          },
          keys = {
            {
              "gd",
              function()
                require("omnisharp_extended").telescope_lsp_definitions()
              end,
              desc = "Goto Definition",
            },
          },
          enable_roslyn_analyzers = true,
          organize_imports_on_format = true,
          enable_import_completion = true,
        },
      },
    },
  },
  {
    "Hoffs/omnisharp-extended-lsp.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
    },
  }
}
