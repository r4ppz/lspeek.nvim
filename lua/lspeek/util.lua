local M = {}

--- Returns true if LSP position a is strictly before b
local function pos_lt(a, b)
  if a.line < b.line then
    return true
  end
  if a.line > b.line then
    return false
  end
  return a.character < b.character
end

--- Returns true if LSP position a is before or equal to b
local function pos_lte(a, b)
  return pos_lt(a, b) or (a.line == b.line and a.character == b.character)
end

--- Converts LSP position format to Vim cursor position format
--- LSP: 0-indexed line and character
--- Vim: 1-indexed line and 0-indexed character
--- @param pos lspeek.Preview.Pos LSP position
--- @return { [1]: integer, [2]: integer } Vim cursor position [row, col]
function M.lsp_pos_to_vim_cursor(pos)
  return { pos.line + 1, pos.character }
end

--- Returns true if a location points to the given document position.
--- Used to detect when an LSP result refers to the symbol that
--- originated the request.
--- @param location table lsp.Location or lsp.LocationLink
--- @param search_uri string URI of the document used for the original request
--- @param search_pos table LSP position { line, character }
--- @return boolean
function M.location_matches_position(location, search_uri, search_pos)
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

  -- LSP ranges are start-inclusive and end-exclusive:
  -- start <= pos < end
  return pos_lte(startp, search_pos) and pos_lt(search_pos, endp)
end

--- Removes locations that refer to the position where the request originated.
--- Always returns a list, even when the input is a single Location.
function M.filter_other_locations(result, search_uri, search_pos)
  if vim.islist(result) then
    local filtered = {}

    for _, loc in ipairs(result) do
      if not M.location_matches_position(loc, search_uri, search_pos) then
        filtered[#filtered + 1] = loc
      end
    end

    return filtered
  end

  if M.location_matches_position(result, search_uri, search_pos) then
    return {}
  end

  return { result }
end

--- Returns a loaded buffer for the given URI, loading it if necessary.
function M.ensure_loaded_buf(uri)
  local bufnr = vim.uri_to_bufnr(uri)

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    vim.fn.bufload(bufnr)
  end

  return bufnr
end

return M
