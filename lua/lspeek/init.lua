local M = {}

M.setup = function(opts)
  require("lspeek.config").setup(opts)
end

M.peek_definition = function()
  require("lspeek.core").peek_definition()
end

return M
