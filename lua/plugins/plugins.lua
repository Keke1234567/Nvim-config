return {
  {
    "rmagatti/auto-session",
    config =  function()
      require("auto-session").setup {
        log_level = "error",
        auto_session_suppress_dirs = { "~/", "~/Projects", "~/Downloads", "/" },
        pre_save_cmds = { "Neotree close" },
      }
    end
  },
  {
    "nvim-telescope/telescope.nvim",
    tag = "v0.1.9",
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim',  build = 'make' }
    },
    config = function()
      local actions = require("telescope.actions")
      require("telescope").setup {
        defaults = {
          file_ignore_patterns = { "node_modules", "%.git/" },
          mappings = {
            i = {
              ["<C-CR>"] = actions.select_vertical,
              ["<S-CR>"] = actions.select_horizontal,
            },
            n = {
              ["<C-CR>"] = actions.select_vertical,
              ["<S-CR>"] = actions.select_horizontal,
            },
          },
        },
      }
      vim.keymap.set("n", "<C-p>", require("telescope.builtin").find_files)
      vim.keymap.set("n", "<space>en", function()
        require('telescope.builtin').find_files {
          cwd = vim.fn.stdpath("config")
        }
      end)
      vim.keymap.set("n", "<space>fg", require("telescope.builtin").live_grep)
    end
  },
  {
    "neovim-treesitter/nvim-treesitter",
    dependencies = { 'neovim-treesitter/treesitter-parser-registry' },
    lazy = false,
    build = ':TSUpdate',
    config = function()
      -- Parsers to keep installed. c/lua/markdown/vim/vimdoc/query ship with
      -- Neovim; everything else has to be built here. install() skips
      -- languages already on disk, so this is cheap on startup and
      -- self-healing on a fresh machine. Requires the tree-sitter CLI
      -- (`npm i -g tree-sitter-cli`) and a C compiler to compile a parser.
      require("nvim-treesitter").install({ "python" })

      -- nvim-treesitter's `main` branch dropped the old highlight module, and
      -- Neovim only auto-starts treesitter for the handful of filetypes whose
      -- bundled ftplugin calls start() itself (lua, markdown, query, help).
      -- Everything else — python included — stays on regex highlighting until
      -- something starts it. pcall because start() throws for a filetype with
      -- no parser installed, which is most of them.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
        callback = function(args)
          pcall(vim.treesitter.start, args.buf)
        end,
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({})
      vim.keymap.set("n", "<leader>j", ":BufferLineCyclePrev<CR>", { silent = true })
      vim.keymap.set("n", "<leader>k", ":BufferLineCycleNext<CR>", { silent = true })
      vim.keymap.set("n", "<leader>x", ":bdelete<CR>", { silent = true })
    end,
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    lazy = false,
    init = function()
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
    end,
    config = function()
      require("neo-tree").setup({
        filesystem = {
          hijack_netrw_behavior = "disabled",
          filtered_items = {
            visible = true,
            hide_dotfiles = false,
            hide_gitignored = false,
          },
        },
      })
      vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { silent = true })
    end,
  }
}

