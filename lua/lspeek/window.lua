local config = require("lspeek.config").options
local util = require("lspeek.util")

local M = {}

--- Position in LSP format (0-indexed)
---@class lspeek.Preview.Pos
---@field line integer 0-indexed line number
---@field character integer 0-indexed character offset (UTF-16)

--- Source context where peek_definition was initiated
---@class lspeek.Preview.Source
---@field win integer Source window ID when peek was initiated
---@field buf integer Source buffer number
---@field pos lspeek.Preview.Pos Source cursor position in LSP format
---@field uri string URI of source file

--- Target definition location
---@class lsp.Preview.Target
---@field buf integer Target buffer number
---@field pos lspeek.Preview.Pos Target cursor position in LSP format
---@field filename string Display filename (basename from URI)
---@field full_path string Full filesystem path to target file
---@field uri string URI of target file

--- Preview instance type used by lspeek.window
---@class lspeek.Preview
---@field source lspeek.Preview.Source source context where peek was initiated
---@field target lsp.Preview.Target target definition location
---@field win? integer window id for the floating preview
---@field _winclosed_au? integer autocmd id for WinClosed cleanup (if created)
---@field close? fun(self) method to close this preview
local Preview = {}
Preview.__index = Preview

-- List of previews
local stack = {}

--- Checks if a given buffer is present in the preview stack.
--- @param buf integer
--- @return boolean
local function is_buffer_in_previews(buf)
  for _, preview in ipairs(stack) do
    if preview.target.buf == buf then
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

--- Close all active preview windows and clear the stack.
local function close_all_previews()
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

  if not is_buffer_in_previews(self.target.buf) and vim.api.nvim_buf_is_valid(self.target.buf) then
    vim.bo[self.target.buf].modifiable = true
    pcall(vim.keymap.del, "n", config.keymaps.close, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.vsplit, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.split, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.enter, { buffer = self.target.buf })
  end

  -- Refocus on top of the stack
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

--- Helper to perform jump operation with target buffer
--- @param operation string "vsplit", "split", or "edit"
--- @param preview lspeek.Preview
local function perform_jump_operation(operation, preview)
  local target_buf = preview.target.buf
  local target_pos = util.lsp_pos_to_vim_cursor(preview.target.pos)
  local target_path = vim.api.nvim_buf_get_name(preview.target.buf)

  local source_pos
  if #stack > 1 then
    source_pos = util.lsp_pos_to_vim_cursor(stack[1].source.pos)
  else
    source_pos = util.lsp_pos_to_vim_cursor(preview.source.pos)
  end

  close_all_previews()

  local source_win = vim.api.nvim_get_current_win()

  if operation == "vsplit" then
    vim.cmd("vsplit")
    vim.api.nvim_set_current_buf(target_buf)
    pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
  elseif operation == "split" then
    vim.cmd("split")
    vim.api.nvim_set_current_buf(target_buf)
    pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
  elseif operation == "edit" then
    local current_path = vim.api.nvim_buf_get_name(0)
    if current_path == target_path then
      pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
    else
      vim.cmd("edit " .. vim.fn.fnameescape(target_path))
      pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
    end
  end

  if operation ~= "edit" then
    pcall(vim.api.nvim_win_set_cursor, source_win, source_pos)
  end
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
    perform_jump_operation("vsplit", preview)
  end, map_opts)

  vim.keymap.set("n", config.keymaps.split, function()
    local preview = get_preview_by_win(vim.api.nvim_get_current_win())
    if not preview then
      return
    end
    perform_jump_operation("split", preview)
  end, map_opts)

  vim.keymap.set("n", config.keymaps.enter, function()
    local preview = get_preview_by_win(vim.api.nvim_get_current_win())
    if not preview then
      return
    end
    perform_jump_operation("edit", preview)
  end, map_opts)
end

local function set_preview_win_opts(win, target_buf)
  vim.api.nvim_set_option_value("winbar", "", { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.bo[target_buf].modifiable = false
end

local function register_winclosed_autocmd(win, instance)
  instance._winclosed_au = vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      local preview = get_preview_by_win(tonumber(vim.fn.expand("<afile>")))
      if preview then
        preview:close()
      end
    end,
  })
end

--- Create a floating preview window for a buffer.
--- @param source lspeek.Preview.Source Source context where peek was initiated
--- @param target lsp.Preview.Target Target definition location
--- @return lspeek.Preview|nil
function M.create_preview_floating_window(source, target)
  local limit = config.stack_limit or 0
  if limit > 0 and #stack >= limit then
    vim.notify(("lspeek: preview limit (%d) reached"):format(limit), vim.log.levels.WARN)
    return nil
  end

  ---@type lspeek.Preview
  local instance = {
    source = source,
    target = target,
  }
  setmetatable(instance, Preview)

  local smart = smart_win_opts(config.window.width, config.window.height)
  local win_config = {
    relative = "cursor",
    title_pos = "center",
    style = "minimal",
    anchor = smart.anchor,
    row = smart.row,
    col = smart.col,
    width = config.window.width,
    height = config.window.height,
    border = config.window.border,
    title = target.filename,
  }

  instance.win = vim.api.nvim_open_win(target.buf, true, win_config)
  set_preview_win_opts(instance.win, target.buf)
  set_preview_keymaps(target.buf)
  register_winclosed_autocmd(instance.win, instance)

  table.insert(stack, instance)
  return instance
end

--- Builds a Target object from LSP location response
--- @param location lsp.Location|lsp.LocationLink
--- @param target_buf integer Buffer number of target
--- @param target_fname string Filesystem path to target file
--- @return lsp.Preview.Target
function M.build_target_from_location(location, target_buf, target_fname)
  local range = location.range or location.targetSelectionRange
  local pos = { line = 0, character = 0 }

  if range then
    pos.line = range.start.line
    pos.character = range.start.character
  end

  return {
    buf = target_buf,
    pos = pos,
    filename = vim.fn.fnamemodify(target_fname, ":t"),
    full_path = target_fname,
    uri = location.uri or location.targetUri,
  }
end

function M.get_source()
  return {
    win = 0,
    buf = 0,
    pos = {
      line = vim.fn.line(".") - 1,
      character = vim.fn.col(".") - 1,
    },
    uri = vim.uri_from_fname(vim.api.nvim_buf_get_name(0)),
  }
end

--- Get the preview instance for the current window (if any)
--- @return lspeek.Preview|nil
function M.get_current_preview()
  return get_preview_by_win(vim.api.nvim_get_current_win())
end

return M
