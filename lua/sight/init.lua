require("sight.types")

local M = {}

---@param buf number
---@param opts FloatOpts
---@return number
function M.create_floating_window(buf, opts)
  buf = buf or 0
  opts = opts or {}

  if not vim.api.nvim_buf_is_valid(buf) then
    error("Invalid buffer")
  end

  local width = opts.width or 30
  local height = opts.height or 30
  local border = opts.border or "single"

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    border = border,
  }

  vim.keymap.set("n", "q", "<cmd>close<cr>", {
    buffer = buf,
    silent = true,
    desc = "Close Sight Window",
  })

  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
  vim.api.nvim_set_option_value("readonly", true, { buf = buf })
  vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })

  local win = vim.api.nvim_open_win(buf, true, win_config)
  return win
end

M.setup = function()
  vim.print("Hello World")
end

return M
