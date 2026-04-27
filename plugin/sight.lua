vim.api.nvim_create_user_command("SightPeek", function()
  require("sight").preview_definition()
end, {})
