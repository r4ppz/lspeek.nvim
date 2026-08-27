local Preview = require("lspeek.preview")
local config = require("lspeek.config")
local util = require("lspeek.util")

local M = {}

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
local function open_target(operation, preview)
  Preview.close_all()

  local source_win = vim.api.nvim_get_current_win()
  jump_to_target(operation, preview)

  if operation ~= "edit" then
    local source_pos = util.lsp_pos_to_vim_cursor(preview.source.pos)
    pcall(vim.api.nvim_win_set_cursor, source_win, source_pos)
  end
end

---Set keymaps on the preview buffer for close/split/vsplit/tab/enter/prev/next.
---@param buf integer
function M.set_preview_keymaps(buf)
  local map_opts = { buffer = buf, silent = true, nowait = true }

  local actions = {
    close = function(preview)
      preview:close()
    end,
    vsplit = function(preview)
      open_target("vsplit", preview)
    end,
    split = function(preview)
      open_target("split", preview)
    end,
    tab = function(preview)
      open_target("tab", preview)
    end,
    enter = function(preview)
      open_target("edit", preview)
    end,
    prev = function(preview)
      preview:navigate(-1)
    end,
    next = function(preview)
      preview:navigate(1)
    end,
  }

  for key, fn in pairs(actions) do
    vim.keymap.set("n", config.options.keymaps[key], function()
      local preview = Preview.get_preview_by_win(vim.api.nvim_get_current_win())
      if preview then
        fn(preview)
      end
    end, map_opts)
  end
end

return M
