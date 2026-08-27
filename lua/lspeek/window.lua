local config = require("lspeek.config")
local Preview = require("lspeek.preview")
local keymaps = require("lspeek.keymaps")

local M = {}

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
    border = config.options.window.border,
    anchor = anchor_v .. anchor_h,
    row = is_overflow_h and (cursor.row - 1) or cursor.row,
    col = is_overflow_w and cursor.col or (cursor.col - 1),
  }
end

---Apply window-local options from config and make the buffer non-modifiable.
---@param win integer
---@param target_buf integer
local function set_preview_win_opts(win, target_buf)
  for opt, val in pairs(config.options.window.win_opts or {}) do
    local ok, err = pcall(vim.api.nvim_set_option_value, opt, val, { win = win })
    if not ok then
      vim.notify(("lspeek: skipping invalid win_opts '%s': %s"):format(opt, err), vim.log.levels.WARN)
    end
  end
  vim.bo[target_buf].modifiable = false
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

---Create a new preview floating window for the given source/target locations.
---Returns nil if the stack limit has been reached.
---@param source lspeek.Preview.Source
---@param target lspeek.Preview.Target
---@return lspeek.Preview|nil
function M.create_preview_floating_window(source, target)
  local limit = config.options.stack_limit or 0
  if limit > 0 and Preview.stack_size() >= limit then
    vim.notify(("lspeek: preview limit (%d) reached"):format(limit), vim.log.levels.INFO)
    return nil
  end

  local preview = Preview.new(source, target)

  local win_config = get_window_config(config.options.window.width, config.options.window.height, target.filename)

  preview.win = vim.api.nvim_open_win(target.buf, true, win_config)

  set_preview_win_opts(preview.win, target.buf)
  keymaps.set_preview_keymaps(target.buf)
  preview:register_autocmd()

  Preview.push(preview)
  return preview
end

---Close all open lspeek preview windows.
function M.close_all()
  Preview.close_all()
end
return M
