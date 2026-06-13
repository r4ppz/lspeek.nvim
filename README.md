# lspeek.nvim

A small Neovim plugin to preview LSP definitions and type definitions in a read-only floating window.

[preview vid](https://github.com/user-attachments/assets/eff58491-54f3-469c-b918-c52f59c60dd2)

### Plugin Spec example:

```lua
-- Default config
{
  "r4ppz/lspeek.nvim",
  opts = {
    window = {
      width = 70,
      height = 15,
      border = "single", -- double | rounded | solid | shadow
    },

    -- Limits the number of stack preview windows.
    stack_limit = 5,

    -- LSP can return multiple definitions
    -- (e.g., overloaded functions or multiple clients).
    -- false = open vim.ui.select to pick one (pairs well with a picker plugin).
    -- true  = skip the picker and preview the first result.
    select_first = false,

    -- Preview window is read-only.
    -- To edit you must press on of these keybinds.
    keymaps = {
      close = "q",   -- Close the floating preview window
      split = "s",   -- Open def in a horizontal split
      vsplit = "v",  -- Open def in a vertical split
      enter = "<CR>",-- Open def in the current/new buffer
      tab = "t",     -- Open def in a new tab
    },
  },

  -- Note:
  -- Stores the current cursor position in the buffer-local ' mark before opening a preview.
  -- Aggregates results from multiple active LSP clients (e.g., ts_ls + cssls).
  -- Won't open a preview if your cursor is already sitting at the definition.
  -- Tries its best to restore your exact cursor location when closing windows.

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

---

> Found a bug? Open an [Issue](https://github.com/r4ppz/lspeek.nvim/issues/new) or [PR](https://github.com/r4ppz/lspeek.nvim/pulls) :)

---

_This plugin was inspired by [lspsaga's peek definition](https://nvimdev.github.io/lspsaga/definition/)._

I am trying to keep this minimal and lightweight so no fancy features for now.
If you're looking for similar functionality with many more features, check out these plugins:

- [goto-preview](https://github.com/rmagatti/goto-preview)
- [overlook.nvim](https://github.com/WilliamHsieh/overlook.nvim)
- [lspsaga](https://github.com/nvimdev/lspsaga.nvim)
- [glance.nvim](https://github.com/DNLHC/glance.nvim)
