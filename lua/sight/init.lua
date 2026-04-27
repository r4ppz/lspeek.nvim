require("sight.types")

local M = {}

local default_opts = {
  width = 70,
  height = 15,
  border = "single",
  enter = true,
}

M.config = {}

M.setup = function(user_opts)
  user_opts = user_opts or {}

  for key, _ in pairs(user_opts) do
    if default_opts[key] == nil then
      error(string.format("Invalid configuration key: %s", key))
    end
  end

  M.config = vim.tbl_extend("force", default_opts, user_opts)
end

function M.create_floating_window(buf, opts)
  buf = buf or 0
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(buf) then
    error("Invalid buffer")
  end

  local win_config = {
    relative = "cursor",
    width = opts.width,
    height = opts.height,
    border = opts.border,
    row = 1,
    col = 1,
  }

  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = buf,
    silent = true,
    desc = "Close Sight Window",
  })

  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  local win = vim.api.nvim_open_win(buf, opts.enter, win_config)
  return win
end

return M
