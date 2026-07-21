local config = require("lspeek.config").options
local util = require("lspeek.util")

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
---@param win integer
---@return lspeek.Preview?
local function get_preview_by_win(win)
  for _, preview in ipairs(stack) do
    if preview.win == win then
      return preview
    end
  end
  return nil
end

---Close all stacked previews, suppressing WinClosed events to avoid recursion.
function M.close_all()
  vim.opt.eventignore:append("WinClosed")
  while #stack > 0 do
    pcall(stack[#stack].close, stack[#stack])
  end
  vim.opt.eventignore:remove("WinClosed")
end

---Close this preview, clean up autocmds and keymaps, focus the previous preview.
function Preview:close()
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
    pcall(vim.keymap.del, "n", config.keymaps.close, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.vsplit, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.split, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.tab, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.enter, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.prev, { buffer = self.target.buf })
    pcall(vim.keymap.del, "n", config.keymaps.next, { buffer = self.target.buf })
  end

  if #stack > 0 then
    local top = stack[#stack]
    if top.win and vim.api.nvim_win_is_valid(top.win) then
      vim.api.nvim_set_current_win(top.win)
    end
  end
end

---Compute floating window dimensions and position relative to the editor cursor.
---@param width integer
---@param height integer
---@param title string
---@return vim.api.keyset.win_config
local function get_window_config(width, height, title)
  local ui = vim.api.nvim_list_uis()[1]
  local screen_w, screen_h = ui.width, ui.height
  local cursor = vim.fn.screenpos(0, vim.fn.line("."), vim.fn.col("."))

  -- Determine anchors based on screen boundary overflows
  local is_overflow_h = (cursor.row + height + 2 > screen_h)
  local is_overflow_w = (cursor.col + width > screen_w)

  local anchor_v = is_overflow_h and "S" or "N"
  local anchor_h = is_overflow_w and "E" or "W"

  return {
    relative = "editor",
    style = "minimal",
    title_pos = "center",
    title = title,
    width = width,
    height = height,
    border = config.window.border,
    anchor = anchor_v .. anchor_h,
    row = is_overflow_h and (cursor.row - 1) or cursor.row,
    col = is_overflow_w and cursor.col or (cursor.col - 1),
  }
end

---Open the target file in a split/vsplit/tab/edit and position the cursor.
---@param operation "vsplit"|"split"|"tab"|"edit"
---@param preview lspeek.Preview
local function jump_to_target(operation, preview)
  local target_pos = util.lsp_pos_to_vim_cursor(preview.target.pos)

  if operation == "vsplit" or operation == "split" then
    vim.cmd(operation .. " " .. vim.fn.fnameescape(preview.target.full_path))
  elseif operation == "tab" then
    vim.cmd("tabedit " .. vim.fn.fnameescape(preview.target.full_path))
  elseif operation == "edit" then
    local current_path = vim.api.nvim_buf_get_name(0)
    if current_path ~= preview.target.full_path then
      vim.cmd("edit " .. vim.fn.fnameescape(preview.target.full_path))
    end
  end

  pcall(vim.api.nvim_win_set_cursor, 0, target_pos)
end

---Close all previews then execute a jump operation.
---@param operation "vsplit"|"split"|"tab"|"edit"
---@param preview lspeek.Preview
local function perform_jump_operation(operation, preview)
  M.close_all()

  local source_win = vim.api.nvim_get_current_win()
  jump_to_target(operation, preview)

  if operation ~= "edit" then
    local source_pos = util.lsp_pos_to_vim_cursor(preview.source.pos)
    pcall(vim.api.nvim_win_set_cursor, source_win, source_pos)
  end
end

---Set keymaps on the preview buffer for close/split/vsplit/tab/enter/prev/next.
---@param buf integer
local function set_preview_keymaps(buf)
  local map_opts = { buffer = buf, silent = true, nowait = true }

  ---Navigate between stacked previews.
  ---@param direction integer  -1 for previous, 1 for next
  local function navigate(direction)
    local cur_win = vim.api.nvim_get_current_win()

    for i, preview in ipairs(stack) do
      if preview.win == cur_win then
        local next_idx = ((i - 1 + direction) % #stack) + 1
        local target = stack[next_idx]

        if target and target.win and vim.api.nvim_win_is_valid(target.win) then
          vim.api.nvim_set_current_win(target.win)
          return
        end
      end
    end
  end

  local actions = {
    close = function(p)
      p:close()
    end,
    vsplit = function(p)
      perform_jump_operation("vsplit", p)
    end,
    split = function(p)
      perform_jump_operation("split", p)
    end,
    tab = function(p)
      perform_jump_operation("tab", p)
    end,
    enter = function(p)
      perform_jump_operation("edit", p)
    end,
    prev = function()
      navigate(-1)
    end,
    next = function()
      navigate(1)
    end,
  }

  for key, fn in pairs(actions) do
    vim.keymap.set("n", config.keymaps[key], function()
      local preview = get_preview_by_win(vim.api.nvim_get_current_win())
      if preview then
        fn(preview)
      end
    end, map_opts)
  end
end

---Apply window-local options from config and make the buffer non-modifiable.
---@param win integer
---@param target_buf integer
local function set_preview_win_opts(win, target_buf)
  for opt, val in pairs(config.window.win_opts or {}) do
    local ok, err = pcall(vim.api.nvim_set_option_value, opt, val, { win = win })
    if not ok then
      vim.notify(("lspeek: skipping invalid win_opts '%s': %s"):format(opt, err), vim.log.levels.WARN)
    end
  end
  vim.bo[target_buf].modifiable = false
end

---Register a WinClosed autocmd to auto-close the preview when the user closes the window.
---@param win integer
---@param instance lspeek.Preview
local function register_winclosed_autocmd(win, instance)
  instance._winclosed_au = vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      local preview = get_preview_by_win(win)
      if preview then
        preview:close()
      end
    end,
  })
end

---Create a new preview floating window for the given source/target locations.
---Returns nil if the stack limit has been reached.
---@param source lspeek.Preview.Source
---@param target lspeek.Preview.Target
---@return lspeek.Preview|nil
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

  local win_config = get_window_config(config.window.width, config.window.height, target.filename)

  instance.win = vim.api.nvim_open_win(target.buf, true, win_config)

  set_preview_win_opts(instance.win, target.buf)
  set_preview_keymaps(target.buf)
  register_winclosed_autocmd(instance.win, instance)

  table.insert(stack, instance)
  return instance
end

---Build a target descriptor from an LSP location and loaded buffer info.
---@param location lsp.Location|lsp.LocationLink
---@param target_buf integer
---@param target_fname string
---@return lspeek.Preview.Target
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

---Capture the current editor state as a source descriptor.
---@return lspeek.Preview.Source
function M.get_source()
  return {
    win = vim.api.nvim_get_current_win(),
    buf = vim.api.nvim_get_current_buf(),
    pos = {
      line = vim.fn.line(".") - 1,
      character = vim.fn.col(".") - 1,
    },
    uri = vim.uri_from_fname(vim.api.nvim_buf_get_name(0)),
  }
end

return M
