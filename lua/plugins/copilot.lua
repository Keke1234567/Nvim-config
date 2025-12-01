return {
  {
    "github/copilot.vim"
  },
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    opts = {
      window = {
        layout = "float",
        zindex = 100,
      },
    },
    config = function()
      vim.g.copilot_no_tab_map = true
      vim.keymap.set('i', '<S-Tab>', 'copilot#Accept("\\<S-Tab>")', { expr = true, replace_keycodes = false })
      vim.keymap.set('n', '<C-A-i>', ':CopilotChatToggle<CR>', { noremap = true, silent = true })
    end,
  },
}
