local config = require("sight.config")
local M = {}

function M.create_preview(target_buf, local_opts)
  local opts = vim.tbl_deep_extend("force", config.options, local_opts or {})

  local scratch_buf = vim.api.nvim_create_buf(false, true)
  local lines = vim.api.nvim_buf_get_lines(target_buf, 0, -1, false)
  vim.api.nvim_buf_set_lines(scratch_buf, 0, -1, false, lines)

  local ft = vim.api.nvim_get_option_value("filetype", { buf = target_buf })
  vim.api.nvim_set_option_value("filetype", ft, { buf = scratch_buf })

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

  local buf_options = { modifiable = false, readonly = true, bufhidden = "wipe" }
  for opt, val in pairs(buf_options) do
    vim.api.nvim_set_option_value(opt, val, { buf = scratch_buf })
  end

  return vim.api.nvim_open_win(scratch_buf, opts.enter, win_config)
end

return M
