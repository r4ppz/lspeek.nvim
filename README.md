# lspeek.nvim

A small Neovim plugin to preview LSP definitions and type definitions in a read-only floating window.

[preview vid](https://github.com/user-attachments/assets/eff58491-54f3-469c-b918-c52f59c60dd2)

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
      tab = "t",
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

- `s`/`v`/`t`/`<CR>` inside the preview window opens the definition in a split, vsplit, new tab, current/new buffer.
- You can also use `:LSPeekDef` and `:LSPeekTypeDef` if you prefer commands over the Lua API.
- Opening a preview stores the cursor position in the buffer-local `'` mark.
- Uses `vim.ui.select` for multiple results, better with a picker plugin.
- Won't open a preview if already at the definition.

---

_Inspired by [lspsaga's peek definition](https://nvimdev.github.io/lspsaga/definition/)._
