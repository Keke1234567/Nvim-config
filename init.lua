require("config.lazy")
require("config.set")

vim.cmd[[colorscheme tokyonight]]
vim.g.mapleader = " "
vim.keymap.set("n", "<C-b>", ":Neotree toggle<CR>")
