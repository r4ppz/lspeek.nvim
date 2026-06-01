if vim.g.loaded_lspeek then
  return
end
vim.g.loaded_lspeek = 1

if vim.fn.has("nvim-0.7") ~= 1 then
  vim.notify("lspeek.nvim requires Neovim >= 0.7", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("LSPeekDef", function()
  require("lspeek").peek_definition()
end, { desc = "Preview LSP definition in a float" })

vim.api.nvim_create_user_command("LSPeekTypeDef", function()
  require("lspeek").peek_type_definition()
end, { desc = "Preview LSP type definition in a float" })
