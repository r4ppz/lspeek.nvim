local window = require("lspeek.window")
local util = require("lspeek.util")

local M = {}

--- Opens a preview window to display the definition of the symbol under the cursor.
function M.peek_definition()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  local callback = function(err, result)
    if err then
      vim.notify("lspeek: " .. err.message, vim.log.levels.ERROR)
      return
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("lspeek: No definition found", vim.log.levels.WARN)
      return
    end

    do
      local search_pos = params.position
      local search_uri = params.textDocument.uri

      if vim.islist(result) then
        local filtered = {}
        for _, loc in ipairs(result) do
          if not util.location_contains_position(loc, search_uri, search_pos) then
            table.insert(filtered, loc)
          end
        end
        if #filtered == 0 then
          vim.notify("lspeek: No other definition found", vim.log.levels.WARN)
          return
        end
        result = filtered
      else
        if util.location_contains_position(result, search_uri, search_pos) then
          vim.notify("lspeek: No other definition found", vim.log.levels.WARN)
          return
        end
      end
    end

    -- Save to jumplist
    vim.cmd("normal! m'")

    -- Get only the first def if its a list
    local location = vim.islist(result) and result[1] or result

    local uri = location.uri or location.targetUri
    if not uri:match("^%w+://") then
      uri = vim.uri_from_fname(uri)
    end

    local target_buf = vim.uri_to_bufnr(uri)
    local target_fname = vim.uri_to_fname(uri)

    if not vim.api.nvim_buf_is_loaded(target_buf) then
      vim.fn.bufload(target_buf)
    end

    -- Build source object from current context
    ---@type lspeek.Preview.Source
    local source = {
      win = 0,
      buf = 0,
      pos = {
        line = vim.fn.line(".") - 1,
        character = vim.fn.col(".") - 1,
      },
      uri = vim.uri_from_fname(vim.api.nvim_buf_get_name(0)),
    }

    ---@type lsp.Preview.Target
    local target = window.build_target_from_location(location, target_buf, target_fname)

    -- Create the preview with source and target objects
    local preview = window.create_preview_floating_window(source, target)

    -- Set cursor to target position
    if preview and preview.win and vim.api.nvim_win_is_valid(preview.win) then
      local cursor_pos = util.lsp_pos_to_vim_cursor(target.pos)
      pcall(vim.api.nvim_win_set_cursor, preview.win, cursor_pos)
    end
  end

  vim.lsp.buf_request(0, "textDocument/definition", params, callback)
end

return M
