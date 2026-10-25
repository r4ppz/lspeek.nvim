local config = require("lspeek.config")
local window = require("lspeek.window")
local util = require("lspeek.util")

local M = {}

---Open a single LSP location in a preview window.
---@param location lspeek.LspLocation|lspeek.LspLocationLink
local function open_preview(location)
  local uri = util.normalize_uri(location.uri or location.targetUri)
  local bufnr = util.ensure_loaded_buf(uri)
  local fname = vim.uri_to_fname(uri)

  local target = window.build_target_from_location(location, bufnr, fname, location.offset_encoding)

  local preview = window.create_preview_floating_window(target)

  if preview and vim.api.nvim_win_is_valid(preview.win) then
    pcall(
      vim.api.nvim_win_set_cursor,
      preview.win,
      util.lsp_pos_to_vim_cursor(target.pos, target.buf, target.offset_encoding)
    )
  end
end

---Open a vim.ui.select picker or directly show the first location.
---@param locations (lspeek.LspLocation|lspeek.LspLocationLink)[]
---@param label string
local function open_or_pick_location(locations, label)
  vim.cmd("normal! m'")

  if #locations == 1 or config.options.select_first then
    open_preview(locations[1])
  else
    vim.ui.select(locations, {
      prompt = "Select " .. label .. ":",
      format_item = util.format_location,
    }, function(choice)
      if choice then
        open_preview(choice)
      end
    end)
  end
end

---Collect and decorate locations from all LSP client responses.
---@param results table<integer, {err: any, result: any, client: any, params: any}>
---@return (lspeek.LspLocation|lspeek.LspLocationLink)[], boolean, boolean
local function collect_client_locations(results)
  local all_locations = {}
  local had_cursor = false
  local had_error = false

  for client_id, res in pairs(results) do
    if res.err then
      had_error = true
    end

    local client = res.client or vim.lsp.get_client_by_id(client_id)
    local client_name = client and client.name or "?"
    local encoding = (client and client.offset_encoding) or "utf-16"

    if not res.err and res.result then
      local items = vim.islist(res.result) and res.result or { res.result }
      ---@cast items (lspeek.LspLocation|lspeek.LspLocationLink)[]

      local params = res.params
      local search_uri = params and params.textDocument and params.textDocument.uri
      local search_pos = params and params.position

      for _, loc in ipairs(items) do
        local at_cursor = search_uri ~= nil
          and search_pos ~= nil
          and util.location_matches_position(loc, search_uri, search_pos)

        if at_cursor then
          had_cursor = true
        else
          ---@cast loc lspeek.LspLocation
          loc.client_name = client_name
          loc.offset_encoding = encoding
          table.insert(all_locations, loc)
        end
      end
    end
  end

  return all_locations, had_cursor, had_error
end

---Send an LSP request and route results to the preview/picker flow.
---@param method string  e.g. "textDocument/definition"
---@param label string   human-readable label for notifications
local function peek_request(method, label)
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP client attached", vim.log.levels.WARN)
    return
  end

  -- Only query clients that support the requested method.
  local supported = {}
  for _, client in ipairs(clients) do
    if client:supports_method(method) then
      table.insert(supported, client)
    end
  end
  if #supported == 0 then
    vim.notify(("No LSP client supports %s"):format(method), vim.log.levels.WARN)
    return
  end
  clients = supported

  local results = {}
  local remaining = #clients
  local all_sent = false

  local function handle_results()
    if vim.tbl_isempty(results) then
      vim.notify(("No %s found"):format(label), vim.log.levels.INFO)
      return
    end

    local locations, had_cursor, had_error = collect_client_locations(results)

    if #locations == 0 then
      if had_cursor and not had_error then
        vim.notify(("Already at %s"):format(label), vim.log.levels.INFO)
      else
        vim.notify(("No %s found"):format(label), vim.log.levels.INFO)
      end
      return
    end

    open_or_pick_location(locations, label)
  end

  local function maybe_finish()
    if not all_sent or remaining > 0 then
      return
    end
    vim.schedule(function()
      handle_results()
    end)
  end

  for _, client in ipairs(clients) do
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    local responded = false
    local success, _ = client:request(method, params, function(err, result)
      if responded then
        return
      end
      responded = true
      results[client.id] = {
        err = err,
        result = result,
        client = client,
        params = params,
      }
      remaining = remaining - 1
      maybe_finish()
    end, 0)

    if not success and not responded then
      responded = true
      results[client.id] = {
        err = "request failed",
        result = nil,
        client = client,
        params = params,
      }
      remaining = remaining - 1
      maybe_finish()
    end
  end

  all_sent = true
  maybe_finish()
end

---Preview the LSP definition at cursor position.
function M.peek_definition()
  peek_request("textDocument/definition", "definition")
end

---Preview the LSP type definition at cursor position.
function M.peek_type_definition()
  peek_request("textDocument/typeDefinition", "type definition")
end

return M
