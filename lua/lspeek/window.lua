local opts = require("lspeek.config").options

local M = {}

local Preview = {}
Preview.__index = Preview

function Preview:close()
  if vim.api.nvim_win_is_valid(self.win) then
    vim.api.nvim_win_close(self.win, true)

    pcall(vim.keymap.del, "n", opts.keymaps.close, { buffer = self.buf })
    pcall(vim.keymap.del, "n", opts.keymaps.vsplit, { buffer = self.buf })
    pcall(vim.keymap.del, "n", opts.keymaps.split, { buffer = self.buf })
    pcall(vim.keymap.del, "n", opts.keymaps.enter, { buffer = self.buf })

    vim.bo[self.buf].modifiable = true
  end
end

-- Smart Window Helper
local function get_smart_opts(width, height)
  local stats = vim.api.nvim_list_uis()[1]
  local screen_w = stats.width
  local screen_h = stats.height
  local cursor_pos = vim.fn.screenpos(0, vim.fn.line("."), vim.fn.col("."))

  local row, col, anchor

  -- Vertical logic: Space below vs Space above
  if cursor_pos.row + height + 2 > screen_h then
    anchor = "S" -- Pop UP
    row = 0
  else
    anchor = "N" -- Pop DOWN
    row = 1
  end

  -- Horizontal logic
  if cursor_pos.col + width > screen_w then
    anchor = anchor .. "E" -- Align to right
    col = 1
  else
    anchor = anchor .. "W" -- Align to left
    col = 0
  end

  return { row = row, col = col, anchor = anchor }
end

--- Creates a floating preview window for a given buffer and file.
---
--- @param buf integer Buffer handle to display in the preview window.
--- @param filename string Name of the file being previewed (used as window title).
--- @param target_row integer Target row to jump to when entering the buffer.
--- @param target_col integer Target column to jump to when entering the buffer.
--- @return table Preview window instance with methods and state.
function M.create_preview(buf, filename, target_row, target_col)
  local smart = get_smart_opts(opts.window.width, opts.window.height)

  local instance = {
    buf = buf,
    filename = filename,
    target_pos = { target_row, target_col },
  }

  local win_config = {
    relative = "cursor",
    anchor = smart.anchor,
    row = smart.row,
    col = smart.col,
    width = opts.window.width,
    height = opts.window.height,
    border = opts.window.border,
    title = filename,
    title_pos = opts.window.title_pos,
    style = "minimal",
  }

  instance.win = vim.api.nvim_open_win(buf, opts.enter, win_config)

  -- Set the "Rulebook"
  setmetatable(instance, Preview)

  -- Apply window-local options
  vim.api.nvim_set_option_value("winbar", "", { win = instance.win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = instance.win })
  vim.bo[instance.buf].modifiable = false

  -- Set keymaps using the instance
  local map_opts = { buffer = buf, silent = true, nowait = true }

  vim.keymap.set("n", opts.keymaps.close, function()
    instance:close()
  end, map_opts)

  vim.keymap.set("n", opts.keymaps.vsplit, function()
    instance:close()
    vim.cmd("vsplit")
    vim.api.nvim_set_current_buf(buf)
  end, map_opts)

  vim.keymap.set("n", opts.keymaps.split, function()
    instance:close()
    vim.cmd("split")
    vim.api.nvim_set_current_buf(buf)
  end, map_opts)

  vim.keymap.set("n", opts.keymaps.enter, function()
    local target_path = vim.api.nvim_buf_get_name(instance.buf)
    local current_path = vim.api.nvim_buf_get_name(0)

    instance:close()

    if current_path == target_path then
      vim.api.nvim_win_set_cursor(0, instance.target_pos)
    else
      vim.cmd("edit " .. vim.fn.fnameescape(target_path))
      vim.api.nvim_win_set_cursor(0, instance.target_pos)
    end
  end, map_opts)

  return instance
end

return M
