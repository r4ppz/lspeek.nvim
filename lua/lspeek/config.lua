---@class lspeek.Config.Window
---@field width integer
---@field height integer
---@field border string|string[]
---@field win_opts? table<string, any>

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

local M = {}

---@type lspeek.Config
M.defaults = {
  window = {
    width = 70,
    height = 15,
    border = "single",
    win_opts = {
      signcolumn = "no",
      winbar = "",
    },
  },

  stack_limit = 5,

  select_first = false,

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
M.options = vim.deepcopy(M.defaults)

---Set up lspeek with user options. Merges with defaults.
---@param user_opts? lspeek.Config
function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
