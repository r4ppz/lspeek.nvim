# lspeek.nvim

A small Neovim plugin to preview LSP definitions in a read-only floating window.

[video](https://github.com/user-attachments/assets/2479b79e-c2ac-4fdf-a2af-065095ed9eb8)

## Installation

```lua
-- Plugin spec
{
  "r4ppz/lspeek.nvim",
  opts = {
    window = {
      width = 70,
      height = 15,
      border = "single",
      title_pos = "center",
    },

    stack_limit = 7,

    keymaps = {
      close = "q",
      split = "s",
      vsplit = "v",
      enter = "<CR>",
    },
  },
},
```
