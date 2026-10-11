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
        "clangd",
        "pyright",
        "ruff",
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

      -- C / C++ / ObjC. clangd is a real compiler frontend, so it wants to
      -- know the exact flags each file is built with. It looks for a
      -- `compile_commands.json` (or `compile_flags.txt`) walking up from the
      -- file; with neither, it falls back to `fallbackFlags` below — which is
      -- enough for single-file scratch programs like ~/projects/c_things.
      -- For a real multi-file project, generate the DB instead:
      --   bear -- make          (Makefile builds)
      --   cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ...
      --
      -- offsetEncoding is not cosmetic: clangd speaks UTF-8 offsets while the
      -- LSP spec (and blink.cmp's default capabilities) assume UTF-16.
      -- Without pinning it, nvim warns about mismatched offset_encoding and
      -- column positions drift on non-ASCII lines.
      vim.lsp.config('clangd', {
        cmd = {
          'clangd',
          '--background-index',
          '--clang-tidy',
          '--header-insertion=iwyu',
          '--completion-style=detailed',
          -- clangd 22 requires an explicit value here; the bare flag
          -- (as most configs online still write it) exits with code 1.
          '--function-arg-placeholders=true',
        },
        capabilities = { offsetEncoding = { 'utf-8' } },
        init_options = {
          fallbackFlags = { '-std=c17', '-Wall', '-Wextra' },
        },
      })
      vim.lsp.enable('clangd')

      -- Python. Two servers attach to the same buffer on purpose, each owning
      -- a job the other is worse at:
      --   pyright — types, hover, go-to-definition, import-aware completion
      --   ruff    — lint + format + import sorting (the flake8/isort/black
      --             stack collapsed into one binary)
      -- Left alone they'd both report unused imports and both offer to format,
      -- so the two configs below explicitly hand each duty to one server.
      --
      -- The interpreter is the thing that actually matters here: pyright
      -- resolves imports against exactly one environment. Point it at the
      -- wrong one and every third-party import is underlined "could not be
      -- resolved" while the code runs fine. Order of preference below is an
      -- activated $VIRTUAL_ENV, then a venv checked into the project root,
      -- then the system python3.
      local function venv_python(root)
        local venv = os.getenv("VIRTUAL_ENV")
        if venv then
          return venv .. "/bin/python"
        end
        for _, dir in ipairs({ ".venv", "venv" }) do
          local p = (root or vim.fn.getcwd()) .. "/" .. dir .. "/bin/python"
          if (vim.uv or vim.loop).fs_stat(p) then
            return p
          end
        end
        return vim.fn.exepath("python3")
      end

      vim.lsp.config('pyright', {
        -- settings.* is baked in at startup, but the venv can only be found
        -- once the server knows its root directory — hence resolving it here
        -- rather than in the static table below. Restart the server
        -- (:LspRestart) after creating a venv in an already-open project.
        before_init = function(_, config)
          config.settings.python.pythonPath = venv_python(config.root_dir)
        end,
        settings = {
          python = {
            analysis = {
              -- "basic" flags real type errors without demanding annotations
              -- everywhere; "strict" turns unannotated code into a wall of
              -- red, "off" gives up type checking entirely.
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              -- "workspace" type-checks every file in the project on every
              -- edit — fine for a package, painful in a big repo. Open files
              -- only; ruff still lints the rest on save.
              diagnosticMode = "openFilesOnly",
            },
          },
          -- ruff sorts imports (isort rules). Without this both servers offer
          -- a source.organizeImports action and they disagree on style.
          pyright = { disableOrganizeImports = true },
        },
      })

      vim.lsp.config('ruff', {
        on_attach = function(client, _)
          -- ruff answers hover with the text of the lint rule it matched,
          -- which shadows pyright's type signature — whichever server replies
          -- first wins the popup. Only one of them should be hoverable.
          client.server_capabilities.hoverProvider = false
        end,
      })

      vim.lsp.enable({ 'pyright', 'ruff' })

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
