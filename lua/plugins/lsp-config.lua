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

      -- Godot's LSP is served *by the Godot editor itself* on TCP :6005. The
      -- built-in gdscript config hardcodes 127.0.0.1, which does NOT reach
      -- the Windows host from WSL (loopback isn't mirrored — see the
      -- wsl-lmstudio-networking memory). Redirect the connect target to the
      -- mirrored Windows LAN IP so nvim can actually talk to the running
      -- editor.
      --
      -- Requires on the Windows side, once, per project:
      --   * Godot editor running with the project open.
      --   * Editor Settings → Network → Language Server → Remote Host = "*"
      --     (default is 127.0.0.1, which only serves Windows loopback).
      --   * Windows firewall: allow inbound TCP 6005 for Godot.exe
      --     (`New-NetFirewallRule -DisplayName "Godot LSP" -Direction Inbound
      --     -Action Allow -Protocol TCP -LocalPort 6005 -Program "C:\path\to\Godot.exe"`).
      --
      -- If Godot isn't running / not reachable, the LSP client just fails to
      -- attach silently; snippets + buffer completion still work.
      local gd_port = tonumber(os.getenv("GDScript_Port")) or 6005
      vim.lsp.config('gdscript', {
        cmd = vim.lsp.rpc.connect(require("util.wsl_host").ip(), gd_port),
      })
      vim.lsp.enable('gdscript')
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
