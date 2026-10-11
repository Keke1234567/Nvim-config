-- Buffer-local setup for Python files.
--
-- Lives in after/ftplugin so it runs *after* Neovim's bundled
-- ftplugin/python.vim (which sets its own indent options) — otherwise the
-- runtime file would overwrite these.

-- The global default is 2 spaces (config/set.lua). PEP 8 says 4, and ruff
-- reindents to 4 on format regardless of what you typed, so matching it here
-- avoids a diff on every save.
vim.bo.tabstop = 4
vim.bo.softtabstop = 4
vim.bo.shiftwidth = 4
vim.bo.expandtab = true

-- ruff's default line length (inherited from black) is 88. Shown as a guide
-- only — nothing hard-wraps.
vim.opt_local.colorcolumn = "89"

-- Format / organize imports on demand. Both are ruff code actions, but
-- formatting goes through vim.lsp.buf.format so it also works if ruff is
-- swapped for something else later. The filter is belt-and-braces: pyright
-- doesn't advertise documentFormatting, so it would be skipped anyway.
vim.keymap.set("n", "<leader>cf", function()
  vim.lsp.buf.format({ async = false, filter = function(c) return c.name == "ruff" end })
end, { buffer = true, desc = "Python: format (ruff)" })

vim.keymap.set("n", "<leader>ci", function()
  -- "source.organizeImports" prefix-matches ruff's
  -- "source.organizeImports.ruff"; apply = true skips the picker when it's
  -- the only candidate.
  vim.lsp.buf.code_action({
    context = { only = { "source.organizeImports" }, diagnostics = {} },
    apply = true,
  })
end, { buffer = true, desc = "Python: organize imports (ruff)" })

vim.keymap.set("n", "<leader>ca", function()
  -- Apply every autofixable lint ruff found in the buffer at once.
  vim.lsp.buf.code_action({
    context = { only = { "source.fixAll" }, diagnostics = {} },
    apply = true,
  })
end, { buffer = true, desc = "Python: fix all (ruff)" })
