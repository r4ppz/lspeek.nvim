# lspeek.nvim

A small Neovim plugin to preview LSP definitions in a read-only floating window.

[preview vid](https://github.com/user-attachments/assets/39c47fc7-fc75-46ec-b571-c4af45f818d2)

```lua
-- Plugin spec
{
  "r4ppz/lspeek.nvim",
  opts = {
    window = {
      width = 70,
      height = 15,
      border = "single",
    },

    stack_limit = 7,

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
  },
},
```

_note:_

- Does not open preview window if cursor is already at the definition.
- Limits the number of stack preview windows.
- Preview window is read-only.
- To edit the file, open it in a split or a new buffer.
