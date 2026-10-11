return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      dap.adapters.php = {
        type = "executable",
        command = "node",
        args = { os.getenv("HOME") .. "/projects/vscode-php-debug/out/phpDebug.js" },
      }

      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug",
          port = 9003,
        },
      }

      local js_based_languages = { "typescript", "javascript", "typescriptreact", "javascriptreact" }
      for _, language in ipairs(js_based_languages) do
        dap.configurations[language] = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            program = "${file}",
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
          },
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome against localhost",
            url = "http://localhost:3000",
            webRoot = "${workspaceFolder}",
            userDataDir = vim.fn.expand("~/.vscode-chrome-debug-userdatadir"),
          },
        }
      end

      vim.keymap.set('n', '<F5>', function() require('dap').continue() end)
      vim.keymap.set('n', '<F10>', function() require('dap').step_over() end)
      vim.keymap.set('n', '<F11>', function() require('dap').step_into() end)
      vim.keymap.set('n', '<F12>', function() require('dap').step_out() end)
      vim.keymap.set('n', '<Leader>b', function() require('dap').toggle_breakpoint() end)
      vim.keymap.set('n', '<Leader>B', function() require('dap').set_breakpoint() end)
      vim.keymap.set('n', '<Leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end)
      vim.keymap.set('n', '<Leader>dr', function() require('dap').repl.open() end)
      vim.keymap.set('n', '<Leader>dl', function() require('dap').run_last() end)
    end,
  },
  {
    -- Python debugging via debugpy. Two different interpreters are in play
    -- and conflating them is the usual failure mode:
    --   * the *adapter* interpreter — the one that has debugpy installed.
    --     Mason keeps it in its own venv, so debugpy never has to be added to
    --     a project's dependencies. Install once with `:MasonInstall debugpy`.
    --   * the *program* interpreter — the one your script runs under.
    --     dap-python resolves it per-session from $VIRTUAL_ENV or a
    --     .venv/venv in the cwd, falling back to the adapter's python.
    -- That's why a `pip install`ed library is importable at runtime without
    -- debugpy being in the same env.
    "mfussenegger/nvim-dap-python",
    dependencies = { "mfussenegger/nvim-dap" },
    ft = "python",
    config = function()
      local mason_debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      if not (vim.uv or vim.loop).fs_stat(mason_debugpy) then
        -- Warn rather than fail silently: without this the adapter is
        -- registered against a python with no debugpy and <F5> dies with an
        -- opaque "No module named debugpy".
        vim.notify("debugpy not found — run :MasonInstall debugpy", vim.log.levels.WARN)
        mason_debugpy = vim.fn.exepath("python3")
      end
      local dap_python = require("dap-python")
      dap_python.setup(mason_debugpy)

      -- pytest by default; change to "unittest" or "django" if a project
      -- needs it. Only affects the test_method/test_class helpers below.
      dap_python.test_runner = "pytest"

      vim.keymap.set("n", "<leader>dt", function() dap_python.test_method() end,
        { desc = "DAP: debug nearest test" })
      vim.keymap.set("n", "<leader>dT", function() dap_python.test_class() end,
        { desc = "DAP: debug test class" })
      vim.keymap.set("v", "<leader>ds", function() dap_python.debug_selection() end,
        { desc = "DAP: debug selection" })
    end,
  },
  {
    "mxsdev/nvim-dap-vscode-js",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      require("dap-vscode-js").setup({
        adapters = { "chrome", "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost", "node" },
      })
    end,
  },
  {
    "rcarriga/nvim-dap-ui",
    dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
    config = function()
      local dapui = require("dapui")
      dapui.setup()

      local dap = require("dap")
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    dependencies = { "mfussenegger/nvim-dap", },
    config = function()
      require("nvim-dap-virtual-text").setup()
    end,
  },
  {
    "nvim-telescope/telescope-dap.nvim",
    dependencies = { "mfussenegger/nvim-dap", "nvim-telescope/telescope.nvim" },
    config = function()
      require("telescope").load_extension("dap")
    end,
  },
}
