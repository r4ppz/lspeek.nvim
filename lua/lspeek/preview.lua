local config = require("lspeek.config")

local M = {}

---@class lspeek.Preview.Pos
---@field line integer
---@field character integer

---@class lspeek.Preview.Source
---@field win integer
---@field buf integer
---@field pos lspeek.Preview.Pos
---@field uri string

---@class lspeek.Preview.Target
---@field buf integer
---@field pos lspeek.Preview.Pos
---@field filename string
---@field full_path string
---@field uri string

---@class lspeek.Preview
---@field source lspeek.Preview.Source
---@field target lspeek.Preview.Target
---@field win? integer
---@field _winclosed_au? integer
---@field _closed? boolean
local Preview = {}
Preview.__index = Preview

---@type lspeek.Preview[]
local stack = {}

---Check if a buffer is already open in any preview window.
---@param buf integer
---@return boolean
local function is_buffer_in_previews(buf)
  for _, preview in ipairs(stack) do
    if preview.target.buf == buf then
      return true
    end
  end
  return false
end

---Find the preview whose window handle matches.
---@param win integer?
---@return lspeek.Preview?
function M.get_preview_by_win(win)
  for _, preview in ipairs(stack) do
    if preview.win == win then
      return preview
    end
  end
  return nil
end

---Close this preview, clean up autocmds and keymaps, focus the previous preview.
function Preview:close()
  if self._closed then
    return
  end
  self._closed = true

  if self.win and vim.api.nvim_win_is_valid(self.win) then
    local win = self.win
    self.win = nil
    pcall(vim.api.nvim_win_close, win, true)
  end

  for i, preview in ipairs(stack) do
    if preview == self then
      table.remove(stack, i)
      break
    end
  end

  if self._winclosed_au then
    pcall(vim.api.nvim_del_autocmd, self._winclosed_au)
    self._winclosed_au = nil
  end

  if not is_buffer_in_previews(self.target.buf) and vim.api.nvim_buf_is_valid(self.target.buf) then
    vim.bo[self.target.buf].modifiable = true
    for _, key in ipairs(vim.tbl_keys(config.options.keymaps)) do
      pcall(vim.keymap.del, "n", config.options.keymaps[key], { buffer = self.target.buf })
    end
  end

  if #stack > 0 then
    local top = stack[#stack]
    if top.win and vim.api.nvim_win_is_valid(top.win) then
      vim.api.nvim_set_current_win(top.win)
    end
  end
end

---Navigate between stacked previews.
---@param direction integer  -1 for previous, 1 for next
function Preview:navigate(direction)
  local cur_win = vim.api.nvim_get_current_win()

  for i, preview in ipairs(stack) do
    if preview.win == cur_win then
      local next_idx = ((i - 1 + direction) % #stack) + 1
      local target = stack[next_idx]

      if target and target.win and vim.api.nvim_win_is_valid(target.win) then
        vim.api.nvim_set_current_win(target.win)
      end
      return
    end
  end
end

---Register a WinClosed autocmd to auto-close the preview when the window is closed.
function Preview:register_autocmd()
  local win = self.win
  self._winclosed_au = vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      local preview = M.get_preview_by_win(win)
      if preview then
        preview:close()
      end
    end,
  })
end

---Close all stacked previews, suppressing WinClosed events to avoid recursion.
function M.close_all()
  vim.opt.eventignore:append("WinClosed")
  while #stack > 0 do
    pcall(stack[#stack].close, stack[#stack])
  end
  vim.opt.eventignore:remove("WinClosed")
end

---Push a preview instance onto the stack.
---@param instance lspeek.Preview
function M.push(instance)
  table.insert(stack, instance)
end

---Number of currently stacked previews.
---@return integer
function M.stack_size()
  return #stack
end

---Create a preview instance from a source/target pair (not yet opened).
---@param source lspeek.Preview.Source
---@param target lspeek.Preview.Target
---@return lspeek.Preview
function M.new(source, target)
  return setmetatable({ source = source, target = target }, Preview)
end

return M
