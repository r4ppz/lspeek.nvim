# lspeek.nvim

A small Neovim plugin to preview LSP definitions in a read-only floating window.

_note:_

- Does not open preview if already at definition
- Preview window is read-only
- Limit number of stacked preview windows

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
