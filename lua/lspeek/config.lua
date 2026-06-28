---@class lspeek.Config.Window
---@field width integer
---@field height integer
---@field border string|string[]

---@class lspeek.Config.Keymap
---@field close string
---@field split string
---@field vsplit string
---@field enter string
---@field tab string
---@field prev string
---@field next string

---@class lspeek.Config
---@field window? lspeek.Config.Window
---@field keymaps? lspeek.Config.Keymap
---@field stack_limit? integer
---@field select_first? boolean
---@field show_line_numbers? boolean

local M = {}

---@type lspeek.Config
M.defaults = {
  window = {
    width = 70,
    height = 15,
    border = "single",
  },

  stack_limit = 5,

  select_first = false,

  show_line_numbers = false,

  keymaps = {
    close = "q",
    split = "s",
    vsplit = "v",
    enter = "<CR>",
    tab = "t",
    prev = "[",
    next = "]",
  },
}

---@type lspeek.Config
M.options = {}

---@param user_opts? lspeek.Config
function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
