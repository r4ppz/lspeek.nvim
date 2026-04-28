---@class WindowConfig
---@field width integer Window width in characters
---@field height integer Window height in lines
---@field border string|string[] Window border style (e.g., "single", "double", "rounded")
---@field title_pos? string Position of the title ("left", "center", "right")

---@class KeymapConfig
---@field close string Keymap to close the preview window
---@field split string Keymap to open definition in horizontal split
---@field vsplit string Keymap to open definition in vertical split
---@field enter string Keymap to open definition in current buffer

---@class LspeekConfig
---@field window? WindowConfig Window configuration options
---@field enter? boolean Whether to enter the preview window on open
---@field keymaps? KeymapConfig Keymap configuration

local M = {}

---@type LspeekConfig
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

---@type LspeekConfig
M.options = {}

---Merge user options with defaults and store the result
---@param user_opts? LspeekConfig User-provided configuration options
---@return nil
function M.setup(user_opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
