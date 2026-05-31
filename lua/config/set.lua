local opt = vim.opt

opt.tabstop = 2
opt.smartindent = true
opt.shiftwidth = 2
opt.expandtab = true
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true

-- Move between splits without the Ctrl-w prefix
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")


vim.cmd[[colorscheme tokyonight-night]]

