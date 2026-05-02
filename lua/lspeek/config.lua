---@class lspeek.Config.Window
---@field width integer Window width in characters
---@field height integer Window height in lines
---@field border string|string[] Window border style (e.g., "single", "double", "rounded")
---@field title_pos? string Position of the title ("left", "center", "right")

---@class lspeek.Config.Keymap
---@field close string Keymap to close the preview window
---@field split string Keymap to open definition in horizontal split
---@field vsplit string Keymap to open definition in vertical split
---@field enter string Keymap to open definition in current buffer

---@class lspeek.Config
---@field window? lspeek.Config.Window Window configuration options
---@field keymaps? lspeek.Config.Keymap Keymap configuration
---@field stack_limit? integer Maximum number of nested preview windows to keep on the stack

local M = {}

---@type lspeek.Config
M.defaults = {
  window = {
    width = 70,
    height = 15,
    border = "single",
    title_pos = "center",
  },

  stack_limit = 5,

  keymaps = {
    close = "q",
    split = "s",
    vsplit = "v",
    enter = "<CR>",
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
