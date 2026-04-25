require("sight.types")

local M = {}

local default_config = {
  width = 60,
  height = 40,
  border = "rounded",
}

---@param buf? number
---@param opts? FloatOpts
---@return number win_id
function M.create_floating_window(buf, opts)
  buf = buf or 0
  opts = vim.tbl_deep_extend("force", default_config, opts or {})

  if buf == 0 then
    buf = vim.api.nvim_get_current_buf()
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    error("Invalid buffer")
  end

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 0,
    width = opts.width,
    height = opts.height,
    border = opts.border,
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
