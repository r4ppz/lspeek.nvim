local window = require("lspeek.window")

local M = {}

--- Opens a preview window to display the definition of the symbol under the cursor.
--- Utilizes the LSP `textDocument/definition` request to fetch the definition location.
--- If the definition is found, it loads the target buffer and creates a preview window.
--- If no definition is found or an error occurs, a notification is displayed.
---@return nil
function M.peek_definition()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  ---@param err? lsp.ResponseError LSP error object, if any error occurred
  ---@param result? lsp.Location|lsp.Location[] LSP definition result (single Location or list)
  local callback = function(err, result)
    if err then
      vim.notify("lspeek: " .. err.message, vim.log.levels.ERROR)
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("lspeek: No definition found", vim.log.levels.WARN)
      return
    end

    -- Get only the first def if its a list
    ---@type lsp.Location|lsp.LocationLink
    local location = vim.islist(result) and result[1] or result
    local target_buf = vim.uri_to_bufnr(location.uri or location.targetUri)

    local target_fname = vim.uri_to_fname(location.uri or location.targetUri)
    local filename = vim.fn.fnamemodify(target_fname, ":t")

    if not vim.api.nvim_buf_is_loaded(target_buf) then
      vim.fn.bufload(target_buf)
    end

    local range = location.range or location.targetSelectionRange
    local row = 1
    local col = 0
    if range then
      row = range.start.line + 1
      col = range.start.character
    end

    local ok, preview = pcall(window.create_preview, target_buf, filename, row, col)

    if not ok or not preview then
      return
    end

    -- Guard against unexpected invalid preview window handle
    if range and preview.win and vim.api.nvim_win_is_valid(preview.win) then
      pcall(vim.api.nvim_win_set_cursor, preview.win, { row, col })
    end
  end

  vim.lsp.buf_request(0, "textDocument/definition", params, callback)
end

return M
