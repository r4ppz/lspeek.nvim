---@class lspeek

local M = {}

---@param opts? lspeek.Config
function M.setup(opts)
  require("lspeek.config").setup(opts)
end

function M.peek_definition()
  require("lspeek.core").peek_definition()
end

function M.peek_type_definition()
  require("lspeek.core").peek_type_definition()
end

function M.close_all()
  require("lspeek.window").close_all()
end

return M
