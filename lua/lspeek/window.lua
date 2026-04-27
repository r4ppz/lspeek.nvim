local config = require("lspeek.config")
local M = {}

local function clone_buffer(buf)
  local scratch_buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(scratch_buf, 0, -1, false, lines)

  local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
  vim.api.nvim_set_option_value("filetype", ft, { buf = scratch_buf })

  return scratch_buf
end

function M.create_preview(target_buf)
  local opts = config.options

  local scratch_buf = clone_buffer(target_buf)

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = opts.window.width,
    height = opts.window.height,
    border = opts.window.border,
  }

  vim.keymap.set("n", opts.keymaps.close, "<cmd>close<cr>", {
    buffer = scratch_buf,
    silent = true,
    nowait = true,
  })

  local win = vim.api.nvim_open_win(scratch_buf, opts.enter, win_config)

  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })
  vim.api.nvim_set_option_value("modifiable", false, { buf = scratch_buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = scratch_buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = scratch_buf })

  return win
end

return M
