-- LSP-driven completion menu (the VSCode-style dropdown).
--
-- This is the *engine/UI*, not a data source. The suggestions come from
-- whatever feeds it: `lsp` (ts_ls, lua_ls, omnisharp — e.g. `createRoot`
-- pulled from node_modules' .d.ts files), `path`, `snippets`, `buffer`.
--
-- Distinct from minuet-ai (ai.lua): that's inline AI ghost-text on <Tab>;
-- this is the discrete completion popup. They coexist — different keymaps.
--
-- Keymaps (insert mode, "enter" preset — does NOT clash with minuet):
--   <C-space>      open menu / toggle docs
--   <C-n> / <C-p>  (or <Up>/<Down>) select next / prev
--   <CR>           accept selected item; falls back to a real newline
--                  when nothing is highlighted / the menu is closed
--   <C-y>          accept
--   <C-e>          dismiss
return {
  {
    "saghen/blink.cmp",
    -- Release tag ships a prebuilt Rust fuzzy-matcher binary, so no
    -- `cargo build` step is needed on install.
    version = "*",
    event = "InsertEnter",
    opts = {
      keymap = { preset = "default" },
      completion = {
        menu = { auto_show = true },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      -- Function signature / param hints while typing a call.
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
  },
}
