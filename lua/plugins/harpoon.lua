-- Harpoon v2: a hand-curated, per-project list of files bound to number keys.
--
-- Distinct from bufferline (plugins.lua): buffers accumulate on their own as
-- you open things, so the bar is noise by mid-session. This list only holds
-- what you explicitly add, in an order you control, and persists across
-- restarts (keyed by cwd, under stdpath("data")/harpoon).
--
-- Keymaps (normal mode):
--   <leader>a      add current file to the list
--   <leader>md     remove current file from the list
--   m1..m4         (re)assign slot N to the current file
--   <leader>1..4   jump to entry N, restoring its saved cursor position
--   [h / ]h        previous / next entry
--   <C-e>          toggle the quick menu (an editable buffer: reorder lines,
--                  dd to remove, :w / q / <Esc> to apply)
--
-- m1..m4 / <leader>1..4 mirror vim's mN / 'N mark syntax, which is the whole
-- point: vim reserves marks 0-9 for the shada file and rejects `m1` outright
-- ("Argument must be a letter"), so nothing is shadowed by taking them here.
-- Cost: pressing `m` and *pausing* now waits timeoutlen (300ms) before it
-- commits to being a set-mark. Typing `ma` at speed is unaffected — the `a`
-- fails to extend any mapping and falls through immediately.
--
-- Removal semantics differ by route, and the difference matters for muscle
-- memory. remove() nils the slot in place, so entries below keep their
-- numbers. Deleting a line in the quick menu instead *compacts* the list
-- (resolve_displayed rebuilds it positionally), silently renumbering
-- everything below the deletion. Blank the line rather than dd-ing it to
-- punch a hole while leaving the other indices alone.
--
-- Key choices deviate from the upstream README because of existing binds:
--   * <C-S-P>/<C-S-N> (upstream prev/next) collapse to <C-p>/<C-n> unless the
--     kitty keyboard protocol is armed, and <C-p> is telescope find_files.
--     [h/]h instead, matching the [d/]d diagnostic maps in lsp-config.lua.
--   * <C-h/t/n/s> (upstream jumps) are unusable here: <C-h> is window-left.
return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")
      harpoon:setup()

      vim.keymap.set("n", "<leader>a", function()
        harpoon:list():add()
      end, { desc = "Harpoon: add file" })

      vim.keymap.set("n", "<leader>md", function()
        harpoon:list():remove()
      end, { desc = "Harpoon: remove file" })

      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = "Harpoon: quick menu" })

      for i = 1, 4 do
        -- 'N jumps, mN (re)assigns — replace_at also dedupes, dropping the
        -- file's previous slot if it was already pinned elsewhere.
        vim.keymap.set("n", "<leader>" .. i, function()
          harpoon:list():select(i)
        end, { desc = "Harpoon: jump to " .. i })

        vim.keymap.set("n", "m" .. i, function()
          harpoon:list():replace_at(i)
        end, { desc = "Harpoon: set slot " .. i })
      end

      vim.keymap.set("n", "[h", function()
        harpoon:list():prev()
      end, { desc = "Harpoon: previous" })

      vim.keymap.set("n", "]h", function()
        harpoon:list():next()
      end, { desc = "Harpoon: next" })
    end,
  },
}
