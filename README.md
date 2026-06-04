# lspeek.nvim

A small Neovim plugin to preview LSP definitions and type definitions in a read-only floating window.

[preview vid](https://github.com/user-attachments/assets/39c47fc7-fc75-46ec-b571-c4af45f818d2)

```lua
-- Plugin spec:
{
  "r4ppz/lspeek.nvim",
  opts = {
    window = {
      width = 70,
      height = 15,
      border = "single",
    },

    -- Limits the number of stack preview windows.
    stack_limit = 5,

    -- LSP can return multiple definitions (e.g., overloaded functions).
    -- false = open vim.ui.select to pick one (default).
    -- true  = skip the picker and jump to the first result.
    select_first = false,

    -- Preview window is read-only.
    -- To edit the file, open it in a split or a new buffer.
    keymaps = {
      close = "q",
      split = "s",
      vsplit = "v",
      enter = "<CR>",
    },
  },

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

- Preview window is positioned relative to the _cursor_.
- `s`/`v`/`<CR>` inside the preview opens the definition in a split, vsplit, or current buffer.
- Opening a preview stores the cursor position in the buffer-local `'` mark.
- Won't open a preview if already at the definition.
- Uses `vim.ui.select` for multiple results — works out of the box, better with a picker plugin.
- You can also use `:LSPeekDef` and `:LSPeekTypeDef` if you prefer commands over the Lua API.

---

_Inspired by [lspsaga's peek definition](https://nvimdev.github.io/lspsaga/definition/)._
