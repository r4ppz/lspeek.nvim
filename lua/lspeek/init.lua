---@class lspeek
---Public API for the lspeek plugin

local M = {}

---Setup and configure lspeek with user options
---@param opts? lspeek.Config User-provided configuration options
---@return nil
M.setup = function(opts)
  require("lspeek.config").setup(opts)
end

---Preview the definition of the symbol under the cursor in a floating window
---@return nil
M.peek_definition = function()
  require("lspeek.core").peek_definition()
end

---Preview the type definition of the symbol under the cursor in a floating window
---@return nil
M.peek_type_definition = function()
  require("lspeek.core").peek_type_definition()
end

return M
