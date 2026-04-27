if vim.fn.has("nvim-0.8") == 0 then
  vim.api.nvim_err_writeln("Sight.nvim requires Neovim 0.8+")
  return
end

vim.api.nvim_create_user_command("SightPeek", function()
  require("sight").preview_definition()
end, { desc = "Preview LSP definition in a float" })
