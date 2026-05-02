local M = {}

--- Converts LSP position format to Vim cursor position format
--- LSP: 0-indexed line and character
--- Vim: 1-indexed line and 0-indexed character
--- @param pos lspeek.Preview.Pos LSP position
--- @return { [1]: integer, [2]: integer } Vim cursor position [row, col]
function M.lsp_pos_to_vim_cursor(pos)
  return { pos.line + 1, pos.character }
end

return M
