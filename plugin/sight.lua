vim.api.nvim_create_user_command("SightPeek", function()
  require("sight").create_floating_window()
end, {})
