local window = require("lspeek.window")
local M = {}

function M.peek_definition()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
    if err then
      vim.notify("lspeek: " .. err.message, vim.log.levels.ERROR)
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("lspeek: No definition found", vim.log.levels.WARN)
      return
    end

    local location = vim.islist(result) and result[1] or result
    local target_buf = vim.uri_to_bufnr(location.uri or location.targetUri)

    if not vim.api.nvim_buf_is_loaded(target_buf) then
      vim.fn.bufload(target_buf)
    end

    local win = window.create_preview(target_buf)

    local range = location.range or location.targetSelectionRange
    if range then
      local row = range.start.line + 1
      vim.api.nvim_win_set_cursor(win, { row, range.start.character })
    end
  end)
end

return M
