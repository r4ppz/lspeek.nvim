---@class lspeek

local M = {}

---Initialize lspeek with user options. Merges with defaults.
---@param opts? lspeek.Config
function M.setup(opts)
  require("lspeek.config").setup(opts)
end

---Preview the LSP definition at cursor position.
function M.peek_definition()
  require("lspeek.core").peek_definition()
end

---Preview the LSP type definition at cursor position.
function M.peek_type_definition()
  require("lspeek.core").peek_type_definition()
end

---Close all open lspeek preview windows.
function M.close_all()
  require("lspeek.window").close_all()
end

return M
