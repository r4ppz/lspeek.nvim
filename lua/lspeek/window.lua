local opts = require("lspeek.config").options

local M = {}

-- Holds all active preview instances
local stack = {}

local Peek = {}
Peek.__index = Peek

local function is_buffer_in_stack(buf)
  for _, inst in ipairs(stack) do
    if inst.buf == buf then
      return true
    end
  end
  return false
end

-- Find the preview instance that owns a given window id
local function find_instance_by_win(win)
  for _, inst in ipairs(stack) do
    if inst.win == win then
      return inst
    end
  end
  return nil
end

function Peek:close()
  -- Close the window if it's still valid
  if vim.api.nvim_win_is_valid(self.win) then
    pcall(vim.api.nvim_win_close, self.win, true)
  end

  -- Remove this specific instance from the stack
  for i, inst in ipairs(stack) do
    if inst == self then
      table.remove(stack, i)
      break
    end
  end

  -- If we registered a WinClosed autocmd for this window, remove it now
  if self._winclosed_au then
    pcall(vim.api.nvim_del_autocmd, self._winclosed_au)
    self._winclosed_au = nil
  end

  -- Cleanup buffer-local settings ONLY if no other stack windows use this buffer
  if not is_buffer_in_stack(self.buf) and vim.api.nvim_buf_is_valid(self.buf) then
    vim.bo[self.buf].modifiable = true
    pcall(vim.keymap.del, "n", opts.keymaps.close, { buffer = self.buf })
    pcall(vim.keymap.del, "n", opts.keymaps.vsplit, { buffer = self.buf })
    pcall(vim.keymap.del, "n", opts.keymaps.split, { buffer = self.buf })
    pcall(vim.keymap.del, "n", opts.keymaps.enter, { buffer = self.buf })
  end

  -- Restore focus to the top-most preview window if present
  if #stack > 0 then
    local top = stack[#stack]
    if vim.api.nvim_win_is_valid(top.win) then
      vim.api.nvim_set_current_win(top.win)
    end
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
--- @return table|nil Preview window instance with methods and state.
function M.create_preview(buf, filename, target_row, target_col)
  -- Enforce stack limit
  local limit = opts.stack_limit or 0

  if limit > 0 and #stack >= limit then
    vim.notify("lspeek: " .. "You're doing too much", vim.log.levels.ERROR)
    return nil
  end

  local instance = {
    buf = buf,
    filename = filename,
    target_pos = { target_row, target_col },
  }

  local smart = get_smart_opts(opts.window.width, opts.window.height)

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

  instance.win = vim.api.nvim_open_win(buf, true, win_config)

  -- Set the "Rulebook"
  setmetatable(instance, Peek)

  -- Apply window-local options
  vim.api.nvim_set_option_value("winbar", "", { win = instance.win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = instance.win })
  vim.bo[instance.buf].modifiable = false

  -- Set keymaps using the instance
  local map_opts = { buffer = buf, silent = true, nowait = true }

  vim.keymap.set("n", opts.keymaps.close, function()
    local inst = find_instance_by_win(vim.api.nvim_get_current_win())
    if inst then
      inst:close()
    end
  end, map_opts)

  vim.keymap.set("n", opts.keymaps.vsplit, function()
    local inst = find_instance_by_win(vim.api.nvim_get_current_win())
    if inst then
      inst:close()
      vim.cmd("vsplit")
      vim.api.nvim_set_current_buf(inst.buf)
    end
  end, map_opts)

  vim.keymap.set("n", opts.keymaps.split, function()
    local inst = find_instance_by_win(vim.api.nvim_get_current_win())
    if inst then
      inst:close()
      vim.cmd("split")
      vim.api.nvim_set_current_buf(inst.buf)
    end
  end, map_opts)

  vim.keymap.set("n", opts.keymaps.enter, function()
    local inst = find_instance_by_win(vim.api.nvim_get_current_win())
    if not inst then
      return
    end

    local target_path = vim.api.nvim_buf_get_name(inst.buf)
    local current_path = vim.api.nvim_buf_get_name(0)

    inst:close()

    if current_path == target_path then
      vim.api.nvim_win_set_cursor(0, inst.target_pos)
    else
      vim.cmd("edit " .. vim.fn.fnameescape(target_path))
      vim.api.nvim_win_set_cursor(0, inst.target_pos)
    end
  end, map_opts)

  -- Register a WinClosed autocmd so cleanup runs even if the window is closed by other means
  local ok, au_id = pcall(vim.api.nvim_create_autocmd, "WinClosed", {
    pattern = tostring(instance.win),
    callback = function()
      -- safe call to close the instance; instance:close handles idempotency
      pcall(function()
        local inst = find_instance_by_win(tonumber(vim.fn.expand("<afile>")))
        if inst then
          inst:close()
        end
      end)
    end,
    once = true,
  })
  if ok then
    instance._winclosed_au = au_id
  end

  table.insert(stack, instance)
  return instance
end

return M
