local M = {}

--- Converts LSP position format to Vim cursor position format
--- LSP: 0-indexed line and character
--- Vim: 1-indexed line and 0-indexed character
--- @param pos lspeek.Preview.Pos LSP position
--- @return { [1]: integer, [2]: integer } Vim cursor position [row, col]
function M.lsp_pos_to_vim_cursor(pos)
  return { pos.line + 1, pos.character }
end


-- Compare LSP positions: a < b
local function pos_lt(a, b)
  if a.line < b.line then
    return true
  end
  if a.line > b.line then
    return false
  end
  return a.character < b.character
end

local function pos_lte(a, b)
  return pos_lt(a, b) or (a.line == b.line and a.character == b.character)
end

--- Determine if an LSP Location or LocationLink contains the given position
--- @param location table lsp.Location or lsp.LocationLink
--- @param search_uri string URI of the document used for the original request
--- @param search_pos table LSP position { line, character }
--- @return boolean
function M.location_contains_position(location, search_uri, search_pos)
  local uri = location.uri or location.targetUri
  local range = location.range or location.targetSelectionRange
  if not uri or not range then
    return false
  end
  if uri ~= search_uri then
    return false
  end
  local startp = range.start
  local endp = range["end"]
  if not startp or not endp then
    return false
  end
  return pos_lte(startp, search_pos) and pos_lt(search_pos, endp)
end

return M
