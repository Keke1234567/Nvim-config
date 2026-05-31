require("config.lazy")
require("config.set")

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })

vim.g.mapleader = " "

-- Force-enable the kitty keyboard protocol so the terminal (WezTerm with
-- enable_kitty_keyboard = true) starts encoding modifier+Enter etc. as
-- distinct CSI-u sequences instead of bare \r. Neovim's auto-detect doesn't
-- reliably fire through WSL/tmux. Disable on suspend/leave so the parent
-- shell isn't left in protocol mode.
local function kkbp(on) io.stdout:write(on and "\27[>1u" or "\27[<u") end
vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" },  { callback = function() kkbp(true)  end })
vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, { callback = function() kkbp(false) end })

