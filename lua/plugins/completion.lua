-- LSP-driven completion menu (the VSCode-style dropdown).
--
-- This is the *engine/UI*, not a data source. The suggestions come from
-- whatever feeds it: `lsp` (ts_ls, lua_ls, omnisharp — e.g. `createRoot`
-- pulled from node_modules' .d.ts files), `path`, `snippets`, `buffer`.
--
-- Distinct from minuet-ai (ai.lua): that's inline AI ghost-text on <Tab>;
-- this is the discrete completion popup. They coexist — different keymaps.
--
-- Keymaps (insert mode, "default" preset — does NOT clash with minuet):
--   <C-space>      open menu / toggle docs
--   <C-n> / <C-p>  (or <Up>/<Down>) select next / prev
--   <S-CR>         accept selected item; falls back to a real newline
--                  when nothing is highlighted / the menu is closed
--   <C-y>          accept
--   <C-e>          dismiss
--
-- Shift+Enter / Ctrl+Enter accept the highlighted suggestion and fall
-- back to a real newline when the menu is closed. Requires the kitty
-- keyboard protocol to be active so the terminal sends modifier+Enter as
-- a distinct keycode rather than bare \r; init.lua force-enables it.
return {
  {
    "saghen/blink.cmp",
    -- Release tag ships a prebuilt Rust fuzzy-matcher binary, so no
    -- `cargo build` step is needed on install.
    version = "*",
    event = "InsertEnter",
    dependencies = {
      -- Snippet engine. blink's `snippets` source needs an engine to expand
      -- placeholders ($1, ${1:foo}, $0) — without one, snippet items insert
      -- as plain text. LuaSnip also loads VSCode-format snippet packs.
      "L3MON4D3/LuaSnip",
      -- Community snippet collection (VSCode format). Ships per-filetype
      -- packs including gdscript/, so .gd files get func/for/match/signal
      -- scaffolding once `from_vscode` lazy-loads them below.
      "rafamadriz/friendly-snippets",
    },
    opts = {
      keymap = {
        preset = "default",
        ['<Tab>'] = { 'select_next', 'snippet_forward', 'fallback' },
        ['<S-Tab>'] = { 'select_prev', 'snippet_backward', 'fallback' },
        ['<CR>'] = { 'accept', 'fallback' },
        ['<Esc>'] = { 'cancel', 'fallback' },
      },
      completion = {
        menu = { auto_show = true },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
      },
      snippets = { preset = "luasnip" },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      fuzzy = { implementation = "prefer_rust_with_warning" },
      -- Function signature / param hints while typing a call.
      signature = { enabled = true },
    },
    opts_extend = { "sources.default" },
    config = function(_, opts)
      -- Leaving a snippet's region ends the session. LuaSnip's defaults set
      -- neither of these, so an expansion you tab out of early (e.g. an LSP
      -- function-call snippet whose param tabstops you never finished) stays
      -- live indefinitely — and a later <Tab> anywhere in the buffer hits
      -- `snippet_forward` above and teleports the cursor back into it.
      require("luasnip").setup({
        region_check_events = "CursorMoved,InsertEnter",
        delete_check_events = "TextChanged,InsertLeave",
      })

      -- friendly-snippets ships VSCode-format packs; LuaSnip needs to be
      -- told to scan its runtimepath for them. lazy_load defers parsing
      -- until a buffer of the matching filetype is opened.
      require("luasnip.loaders.from_vscode").lazy_load()
      require("blink.cmp").setup(opts)
    end,
  },
}
