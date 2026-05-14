# lspeek.nvim

A small Neovim plugin to preview LSP definitions in a read-only floating window.

[preview vid](https://github.com/user-attachments/assets/39c47fc7-fc75-46ec-b571-c4af45f818d2)

```lua
-- note:
-- Does not open preview window if cursor is already at the definition.

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
    stack_limit = 7,

    -- Preview window is read-only.
    -- To edit the file, open it in a split or a new buffer
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
}
```
