local opt = vim.opt

opt.tabstop = 2
opt.smartindent = true
opt.shiftwidth = 2
opt.expandtab = true
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true

-- Hybrid line numbers: relative while moving around, absolute in insert mode
-- and in windows that aren't focused (where relative offsets are meaningless).
-- The `vim.wo.number` guard keeps numbers off in buffers that opted out
-- (terminals, file trees, etc.) instead of forcing them on everywhere.
opt.number = true
opt.relativenumber = true

local numbertoggle = vim.api.nvim_create_augroup("numbertoggle", { clear = true })

vim.api.nvim_create_autocmd({ "InsertLeave", "BufEnter", "WinEnter", "FocusGained" }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number and vim.api.nvim_get_mode().mode ~= "i" then
      vim.wo.relativenumber = true
    end
  end,
})

vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave", "FocusLost" }, {
  group = numbertoggle,
  callback = function()
    if vim.wo.number then
      vim.wo.relativenumber = false
    end
  end,
})

-- Move between splits without the Ctrl-w prefix
vim.keymap.set("n", "<C-h>", "<C-w>h")
vim.keymap.set("n", "<C-j>", "<C-w>j")
vim.keymap.set("n", "<C-k>", "<C-w>k")
vim.keymap.set("n", "<C-l>", "<C-w>l")

-- WezTerm/kkbp quirk: the End key arrives as <Select> (the terminal reports
-- the "Select" X keysym for it under the kitty keyboard protocol). Without
-- a mapping, insert mode inserts the literal text "<Select>". Route it to
-- <End> in every mode where End is expected.
for _, mode in ipairs({ "i", "n", "v", "s", "c" }) do
  vim.keymap.set(mode, "<Select>", "<End>", { desc = "End (kkbp <Select> alias)" })
end

-- Modifier+Backspace (only carried through once kkbp is on, see init.lua).
-- Alt-BS deletes the previous word. Shift-BS is *not* handled here: WezTerm
-- collapses it to plain BS under kkbp mode 1 (both bytes are 0x7f, not
-- counted as ambiguous), so the S-BS map never fires. Shift-BS is rewritten
-- to Ctrl-W in ~/.wezterm.lua (Windows side) instead — nvim just sees C-w.
vim.keymap.set("i", "<A-BS>", "<C-w>", { desc = "Delete previous word" })
vim.keymap.set("c", "<A-BS>", "<C-w>")

-- Re-stat open buffers and reload any whose file changed on disk (e.g.
-- after Godot's built-in editor wrote a .gd file). WSL/Windows boundary
-- doesn't give reliable inotify, so this manual trigger is the backstop.
vim.keymap.set("n", "<leader>r", "<cmd>checktime<cr>", { desc = "Reload changed files" })


vim.cmd[[colorscheme tokyonight-night]]

