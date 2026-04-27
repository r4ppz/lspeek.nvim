local M = {}

M.setup = function(opts)
  require("lspeek.config").setup(opts)
end

M.preview_definition = function()
  require("lspeek.core").preview_definition()
end

return M
