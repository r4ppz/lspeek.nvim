local config = require("lspeek.config").options

local M = {}

--- Preview instance type used by lspeek.window
---@class lspeek.Preview
---@field buf integer buffer number being previewed
---@field win number|nil window id for the floating preview (may be nil until created)
---@field target_pos { row: integer, col: integer } named fields for target cursor position
---@field _winclosed_au integer|nil autocmd id for WinClosed cleanup (if created)
---@field close fun(self) method to close this preview
local Preview = {}
Preview.__index = Preview

-- List of previews
local stack = {}

--- Checks if a given buffer is present in the preview stack.
--- @param buf integer
--- @return boolean
local function is_buffer_in_previews(buf)
  for _, preview in ipairs(stack) do
    if preview.buf == buf then
      return true
    end
  end
  return false
end

--- Retrieves the preview entry associated with a given window.
--- @param win number|nil
--- @return lspeek.Preview|nil
local function get_preview_by_win(win)
  for _, preview in ipairs(stack) do
    if preview.win == win then
      return preview
    end
  end
  return nil
end

function Preview:close()
  if self.win and vim.api.nvim_win_is_valid(self.win) then
    pcall(vim.api.nvim_win_close, self.win, true)
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

  if not is_buffer_in_previews(self.buf) and vim.api.nvim_buf_is_valid(self.buf) then
    vim.bo[self.buf].modifiable = true
    pcall(vim.keymap.del, "n", config.keymaps.close, { buffer = self.buf })
    pcall(vim.keymap.del, "n", config.keymaps.vsplit, { buffer = self.buf })
    pcall(vim.keymap.del, "n", config.keymaps.split, { buffer = self.buf })
    pcall(vim.keymap.del, "n", config.keymaps.enter, { buffer = self.buf })
  end

  if #stack > 0 then
    local top = stack[#stack]
    if top.win and vim.api.nvim_win_is_valid(top.win) then
      vim.api.nvim_set_current_win(top.win)
    end
  end
end

local function smart_win_opts(width, height)
  local ui = vim.api.nvim_list_uis()[1]
  local screen_w, screen_h = ui.width, ui.height
  local cursor = vim.fn.screenpos(0, vim.fn.line("."), vim.fn.col("."))

  local row, col, anchor

  if cursor.row + height + 2 > screen_h then
    anchor = "S"
    row = 0
  else
    anchor = "N"
    row = 1
  end

  if cursor.col + width > screen_w then
    anchor = anchor .. "E"
    col = 1
  else
    anchor = anchor .. "W"
    col = 0
  end

  return { row = row, col = col, anchor = anchor }
end

local function set_preview_keymaps(buf)
  local map_opts = { buffer = buf, silent = true, nowait = true }

  vim.keymap.set("n", config.keymaps.close, function()
    local preview = get_preview_by_win(vim.api.nvim_get_current_win())
    if not preview then
      return
    end

    preview:close()
  end, map_opts)

  vim.keymap.set("n", config.keymaps.vsplit, function()
    local preview = get_preview_by_win(vim.api.nvim_get_current_win())
    if not preview then
      return
    end

    -- Snapshot data we need from the preview before closing everything
    local target_buf = preview.buf
    local tp = preview.target_pos
    local target_pos = { tp.row, tp.col }

    -- Close all previews, then open the target in a vertical split
    M.close_all_previews()

    vim.cmd("vsplit")
    vim.api.nvim_set_current_buf(target_buf)
    pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
  end, map_opts)

  vim.keymap.set("n", config.keymaps.split, function()
    local preview = get_preview_by_win(vim.api.nvim_get_current_win())
    if not preview then
      return
    end

    local target_buf = preview.buf
    local tp = preview.target_pos
    local target_pos = { tp.row, tp.col }

    M.close_all_previews()

    vim.cmd("split")
    vim.api.nvim_set_current_buf(target_buf)
    pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
  end, map_opts)

  vim.keymap.set("n", config.keymaps.enter, function()
    local preview = get_preview_by_win(vim.api.nvim_get_current_win())
    if not preview then
      return
    end

    -- Snapshot path/pos before closing previews
    local target_path = vim.api.nvim_buf_get_name(preview.buf)
    local tp = preview.target_pos
    local target_pos = { tp.row, tp.col }

    -- Close all previews first
    M.close_all_previews()

    local current_path = vim.api.nvim_buf_get_name(0)
    if current_path == target_path then
      pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
    else
      vim.cmd("edit " .. vim.fn.fnameescape(target_path))
      pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
    end
  end, map_opts)
end

local function set_preview_win_opts(win, buf)
  vim.api.nvim_set_option_value("winbar", "", { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.bo[buf].modifiable = false
end

local function register_winclosed_autocmd(win, instance)
  local ok, au_id = pcall(vim.api.nvim_create_autocmd, "WinClosed", {
    pattern = tostring(win),
    callback = function()
      pcall(function()
        local preview = get_preview_by_win(tonumber(vim.fn.expand("<afile>")))
        if preview then
          preview:close()
        end
      end)
    end,
    once = true,
  })
  if ok then
    instance._winclosed_au = au_id
  end
end

--- Create a floating preview window for a buffer.
--- @param buf integer
--- @param filename string
--- @param target_row integer
--- @param target_col integer
--- @return lspeek.Preview|nil
function M.create_preview_floating_window(buf, filename, target_row, target_col)
  local limit = config.stack_limit or 0
  if limit > 0 and #stack >= limit then
    vim.notify("lspeek: " .. "You're doing too much", vim.log.levels.ERROR)
    return nil
  end

  local instance = {
    buf = buf,
    target_pos = { row = target_row, col = target_col },
  }
  setmetatable(instance, Preview)

  local smart = smart_win_opts(config.window.width, config.window.height)
  local win_config = {
    relative = "cursor",
    anchor = smart.anchor,
    row = smart.row,
    col = smart.col,
    width = config.window.width,
    height = config.window.height,
    border = config.window.border,
    title = filename,
    title_pos = config.window.title_pos,
    style = "minimal",
  }

  instance.win = vim.api.nvim_open_win(buf, true, win_config)
  set_preview_win_opts(instance.win, buf)
  set_preview_keymaps(buf)
  register_winclosed_autocmd(instance.win, instance)

  table.insert(stack, instance)
  return instance
end

--- Close all active preview windows and clear the stack.
function M.close_all_previews()
  while #stack > 0 do
    local preview = stack[#stack]
    if not preview then
      break
    end
    pcall(function()
      preview:close()
    end)
  end
end

return M
