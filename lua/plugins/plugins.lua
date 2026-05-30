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
      require("telescope").setup {
        defaults = {
          file_ignore_patterns = { "node_modules", "%.git/" },
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

