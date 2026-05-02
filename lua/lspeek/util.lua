local M = {}

--- Converts LSP position format to Vim cursor position format
--- LSP: 0-indexed line and character
--- Vim: 1-indexed line and 0-indexed character
--- @param pos lspeek.Preview.Pos LSP position
--- @return { [1]: integer, [2]: integer } Vim cursor position [row, col]
function M.lsp_pos_to_vim_cursor(pos)
  return { pos.line + 1, pos.character }
end

--- Builds a Target object from LSP location response
--- @param location lsp.Location|lsp.LocationLink
--- @param target_buf integer Buffer number of target
--- @param target_fname string Filesystem path to target file
--- @return lsp.Preview.Target
function M.build_target_from_location(location, target_buf, target_fname)
  local range = location.range or location.targetSelectionRange
  local pos = { line = 0, character = 0 }

  if range then
    pos.line = range.start.line
    pos.character = range.start.character
  end

  return {
    buf = target_buf,
    pos = pos,
    filename = vim.fn.fnamemodify(target_fname, ":t"),
    full_path = target_fname,
    uri = location.uri or location.targetUri,
  }
end

return M
