local M = {}

M.defaults = {
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

M.options = {}

function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
