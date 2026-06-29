# lspeek.nvim

A small Neovim plugin to preview LSP definitions and type definitions in a read-only floating window.

[preview vid](https://github.com/user-attachments/assets/eff58491-54f3-469c-b918-c52f59c60dd2)

### Plugin spec example

```lua
{
  "r4ppz/lspeek.nvim",
  opts = {
    window = {
      width = 70,
      height = 15,
      border = "single", -- double | rounded | solid | shadow
      -- Window-local options applied to the preview window.
      -- Each key-value pair is set via vim.api.nvim_set_option_value.
      win_opts = {
        number = true, -- show line numbers
      },
    },

    -- Limits the number of stacked preview windows.
    stack_limit = 5,

    -- LSP can return multiple definitions
    -- (e.g., overloaded functions or multiple clients).
    -- false = open vim.ui.select to pick one (pairs well with a picker plugin).
    -- true  = skip the picker and preview the first result.
    select_first = false,

    -- Keymaps available inside the preview window.
    keymaps = {
      close = "q",
      split = "s",
      vsplit = "v",
      enter = "<CR>",
      tab = "t",
      prev = "[",
      next = "]",
    },
  },

  -- Keymaps call the Lua API. Alternatively, use user commands:
  -- :LSPeekDef      -> Peek Definition
  -- :LSPeekTypeDef  -> Peek Type Definition
  keys = {
    {
      "gD",
      function()
        require("lspeek").peek_definition()
      end,
      desc = "Peek Definition (lspeek)",
    },
    {
      "gT",
      function()
        require("lspeek").peek_type_definition()
      end,
      desc = "Peek Type Definition (lspeek)",
    },
  },
}
```

### Features

- Preview definitions and type definitions in a read-only floating window
- Open the target in a split, vsplit, tab, or current buffer
- Stack multiple preview windows and keep peeking deeper
- Navigate between stacked previews with `[` and `]`
- Combines results from all attached LSP clients
- Won't reopen a preview if you're already at the target location
- Saves your cursor position (`'`) before jumping

---

> Found a bug? Open an [issue](https://github.com/r4ppz/lspeek.nvim/issues/new) or [PR](https://github.com/r4ppz/lspeek.nvim/pulls) :)

---

_Inspired by [lspsaga's peek definition](https://nvimdev.github.io/lspsaga/definition/)._

If you're looking for similar functionality with many more features, check out these plugins:

- [goto-preview](https://github.com/rmagatti/goto-preview)
- [overlook.nvim](https://github.com/WilliamHsieh/overlook.nvim)
- [lspsaga](https://github.com/nvimdev/lspsaga.nvim)
- [glance.nvim](https://github.com/DNLHC/glance.nvim)
