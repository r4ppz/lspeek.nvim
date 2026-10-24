local M = {}

---@class lspeek.LspLocation : lsp.Location
---@field client_name? string
---@field offset_encoding? string

---@class lspeek.LspLocationLink : lsp.LocationLink
---@field client_name? string
---@field offset_encoding? string

---Compare two LSP positions (a < b).
---@param a lsp.Position
---@param b lsp.Position
---@return boolean
local function pos_lt(a, b)
  if a.line < b.line then
    return true
  end
  if a.line > b.line then
    return false
  end
  return a.character < b.character
end

---Compare two LSP positions (a <= b).
---@param a lsp.Position
---@param b lsp.Position
---@return boolean
local function pos_lte(a, b)
  return pos_lt(a, b) or (a.line == b.line and a.character == b.character)
end

---Convert an LSP 0-indexed position to a vim 1-indexed cursor {row, col}.
---LSP `character` offsets are in the negotiated encoding (usually UTF-16),
---while Vim columns are byte indices, so convert via vim.str_byteindex.
---@param pos lspeek.Preview.Pos
---@param buf integer buffer to read the target line from
---@param encoding string? LSP offset encoding ("utf-8"|"utf-16"|"utf-32")
---@return { [1]: integer, [2]: integer }
function M.lsp_pos_to_vim_cursor(pos, buf, encoding)
  encoding = encoding or "utf-16"
  local row = pos.line
  local col = pos.character
  if col > 0 and vim.api.nvim_buf_is_valid(buf) then
    local line = (vim.api.nvim_buf_get_lines(buf, row, row + 1, false))[1] or ""
    col = vim.str_byteindex(line, encoding, col, false)
  end
  return { row + 1, col }
end

---Check if a location's range includes the given search position.
---@param location lspeek.LspLocation|lspeek.LspLocationLink
---@param search_uri string
---@param search_pos lsp.Position
---@return boolean
function M.location_matches_position(location, search_uri, search_pos)
  local uri = location.uri or location.targetUri
  local range = location.range or location.targetSelectionRange
  if not uri or not range then
    return false
  end
  if vim.uri_to_fname(M.normalize_uri(uri)) ~= vim.uri_to_fname(M.normalize_uri(search_uri)) then
    return false
  end
  local startp = range.start
  local endp = range["end"]
  if not startp or not endp then
    return false
  end

  -- LSP ranges: start <= pos < end
  if startp.line == endp.line and startp.character == endp.character then
    return search_pos.line == startp.line and search_pos.character == startp.character
  end
  return pos_lte(startp, search_pos) and pos_lt(search_pos, endp)
end

---Filter out the location at the cursor position.
---@param locations (lspeek.LspLocation|lspeek.LspLocationLink)[]
---@param search_uri string
---@param search_pos lsp.Position
---@return (lspeek.LspLocation|lspeek.LspLocationLink)[]
function M.exclude_at_cursor(locations, search_uri, search_pos)
  local filtered = {}

  for _, loc in ipairs(locations) do
    if not M.location_matches_position(loc, search_uri, search_pos) then
      filtered[#filtered + 1] = loc
    end
  end

  return filtered
end

---Format a location for display in vim.ui.select.
---@param location lspeek.LspLocation|lspeek.LspLocationLink
---@return string
function M.format_location(location)
  local fname = vim.uri_to_fname(M.normalize_uri(location.uri or location.targetUri))
  local range = location.range or location.targetSelectionRange
  local line = range and range.start.line + 1 or 0
  ---@diagnostic disable-next-line: undefined-field
  local suffix = location.client_name and (" [" .. location.client_name .. "]") or ""
  return vim.fn.fnamemodify(fname, ":t") .. ":" .. line .. suffix
end

---Ensure the buffer for a URI is loaded, returning its buffer number.
---@param uri string
---@return integer
function M.ensure_loaded_buf(uri)
  local bufnr = vim.uri_to_bufnr(uri)

  if not vim.api.nvim_buf_is_loaded(bufnr) then
    pcall(vim.fn.bufload, bufnr)
  end

  return bufnr
end

---Normalize a URI. If it looks like a plain path, convert to file URI.
---@param uri string
---@return string
function M.normalize_uri(uri)
  if not uri:match("^%w+://") then
    return vim.uri_from_fname(uri)
  end
  return uri
end

return M
