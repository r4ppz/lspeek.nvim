local M = {}

local default_opts = {
  window = {
    width = 70,
    height = 15,
    border = "single",
  },

  enter = true,

  keymaps = {
    close = "q",
  },
}

M.config = {}

M.setup = function(user_opts)
  M.config = vim.tbl_deep_extend("force", default_opts, user_opts or {})
end

function M.create_floating_window(buf, local_opts)
  buf = buf or vim.api.nvim_get_current_buf()

  local config = vim.tbl_deep_extend("force", M.config, local_opts or {})

  if not vim.api.nvim_buf_is_valid(buf) then
    error("Invalid buffer")
  end

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = config.window.width,
    height = config.window.height,
    border = config.window.border,
  }

  vim.keymap.set("n", config.keymaps.close, "<cmd>close<cr>", {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close Sight Window",
  })

  local buf_options = {
    modifiable = false,
    readonly = true,
    bufhidden = "wipe",
  }

  for opt, val in ipairs(buf_options) do
    vim.api.nvim_set_option_value(opt, val, { buf = buf })
  end

  local win = vim.api.nvim_open_win(buf, config.enter, win_config)
  return win
end

return M
