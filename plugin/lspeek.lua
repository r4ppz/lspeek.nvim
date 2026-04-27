if vim.g.loaded_lspeek then
  return
end
vim.g.loaded_lspeek = 1

vim.api.nvim_create_user_command("LSPeekDef", function()
  require("lspeek").peek_definition()
end, { desc = "Preview LSP definition in a float" })
