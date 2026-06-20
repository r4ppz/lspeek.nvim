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

---@class lsp.Preview.Target
---@field buf integer
---@field pos lspeek.Preview.Pos
---@field filename string
---@field full_path string
---@field uri string

---@class lspeek.Preview
---@field source lspeek.Preview.Source
---@field target lsp.Preview.Target
---@field win? integer
---@field _winclosed_au? integer
---@field close? fun(self)
local Preview = {}
Preview.__index = Preview

local stack = {}

local function is_buffer_in_previews(buf)
  for _, preview in ipairs(stack) do
    if preview.target.buf == buf then
      return true
    end
  end
  return false
end

local function get_preview_by_win(win)
  for _, preview in ipairs(stack) do
    if preview.win == win then
      return preview
    end
  end
  return nil
end

local function close_all_previews()
  vim.opt.eventignore:append("WinClosed")
  while #stack > 0 do
    pcall(stack[#stack].close, stack[#stack])
  end
  vim.opt.eventignore:remove("WinClosed")
end

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

local function jump_to_target(operation, preview)
  local target_pos = util.lsp_pos_to_vim_cursor(preview.target.pos)

  if operation == "vsplit" or operation == "split" then
    vim.cmd(operation)
    vim.api.nvim_set_current_buf(preview.target.buf)
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

local function perform_jump_operation(operation, preview)
  close_all_previews()

  local source_win = vim.api.nvim_get_current_win()
  jump_to_target(operation, preview)

  if operation ~= "edit" then
    local source_pos = util.lsp_pos_to_vim_cursor(preview.source.pos)
    pcall(vim.api.nvim_win_set_cursor, source_win, source_pos)
  end
end

local function set_preview_keymaps(buf)
  local map_opts = { buffer = buf, silent = true, nowait = true }

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
      local preview = get_preview_by_win(win)
      if preview then
        preview:close()
      end
    end,
  })
end

---@param source lspeek.Preview.Source
---@param target lsp.Preview.Target
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

  -- Pin to editor grid so closing other floats can't shift this one
  local pos = vim.api.nvim_win_get_position(instance.win)
  vim.api.nvim_win_set_config(instance.win, {
    relative = "editor",
    row = pos[1],
    col = pos[2],
  })

  set_preview_win_opts(instance.win, target.buf)
  set_preview_keymaps(target.buf)
  register_winclosed_autocmd(instance.win, instance)

  table.insert(stack, instance)
  return instance
end

---@param location lsp.Location|lsp.LocationLink
---@param target_buf integer
---@param target_fname string
---@return lsp.Preview.Target
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
