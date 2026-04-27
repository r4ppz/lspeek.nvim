local M = {}

M.setup = function(opts)
  require("sight.config").setup(opts)
end

M.preview_definition = function()
  require("sight.core").preview_definition()
end

return M
