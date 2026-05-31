local window = require("lspeek.window")
local util = require("lspeek.util")

local M = {}

local function open_preview(location)
  local uri = location.uri or location.targetUri

  if not uri:match("^%w+://") then
    uri = vim.uri_from_fname(uri)
  end

  local bufnr = util.ensure_loaded_buf(uri)
  local fname = vim.uri_to_fname(uri)

  local source = window.get_source()
  local target = window.build_target_from_location(location, bufnr, fname)

  local preview = window.create_preview_floating_window(source, target)

  if preview and vim.api.nvim_win_is_valid(preview.win) then
    pcall(vim.api.nvim_win_set_cursor, preview.win, util.lsp_pos_to_vim_cursor(target.pos))
  end
end

function M.peek_definition()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result)
    if err then
      vim.notify(err.message, vim.log.levels.ERROR)
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("No definition found", vim.log.levels.WARN)
      return
    end

    -- Check if we're in a preview window and use that context for filtering
    local current_preview = window.get_current_preview()
    local search_uri = params.textDocument.uri
    ---@type table
    local search_pos = params.position

    if current_preview then
      search_uri = current_preview.target.uri
      search_pos = current_preview.target.pos
    end

    local locations = util.filter_other_locations(result, search_uri, search_pos)

    if #locations == 0 then
      vim.notify("Already at definition", vim.log.levels.WARN)
      return
    end

    vim.cmd("normal! m'")
    open_preview(locations[1])
  end)
end

return M
