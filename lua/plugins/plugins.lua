return {
  {
    "rmagatti/auto-session",
  },
  {
    "github.com/copilot.vim"
  },
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
  },
  {
    "nvim-telescope/telescope.nvim", 
    tag = "v0.1.9",
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim',  build = 'make' }
    },
    config = function()
      vim.keymap.set("n", "<space>fd", require("telescope.builtin").find_files)
      vim.keymap.set("n", "<space>en", function()
        require('telescope.builtin').find_files {
          cwd = vim.fn.stdpath("config")
        }
      end)
    end
  }
}

