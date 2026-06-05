---@class lspeek.Config.Window
---@field width integer Window width in characters
---@field height integer Window height in lines
---@field border string|string[] Window border style (e.g., "single", "double", "rounded")

---@class lspeek.Config.Keymap
---@field close string Keymap to close the preview window
---@field split string Keymap to open definition in horizontal split
---@field vsplit string Keymap to open definition in vertical split
---@field enter string Keymap to open definition in current buffer
---@field tab string Keymap to open definition in a new tab

---@class lspeek.Config
---@field window? lspeek.Config.Window Window configuration options
---@field keymaps? lspeek.Config.Keymap Keymap configuration
---@field stack_limit? integer Maximum number of nested preview windows to keep on the stack
---@field select_first? boolean Skip picker and open first result directly

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

  keymaps = {
    close = "q",
    split = "s",
    vsplit = "v",
    enter = "<CR>",
    tab = "t",
  },
}

---@type lspeek.Config
M.options = {}

---Merge user options with defaults and store the result
---@param user_opts? lspeek.Config User-provided configuration options
---@return nil
function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
