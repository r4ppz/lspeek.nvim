local M = {}

M.defaults = {
  window = {
    width = 70,
    height = 15,
    border = "single",
    title_pos = "center",
  },
  enter = true,

  keymaps = {
    close = "q",
    split = "s",
    vsplit = "v",
    enter = "<CR>",
  },
}

M.options = {}

function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
