local config = require("lspeek.config").options
local window = require("lspeek.window")
local util = require("lspeek.util")

local M = {}

local function open_preview(location)
  local uri = util.normalize_uri(location.uri or location.targetUri)
  local bufnr = util.ensure_loaded_buf(uri)
  local fname = vim.uri_to_fname(uri)

  local source = window.get_source()
  local target = window.build_target_from_location(location, bufnr, fname)

  local preview = window.create_preview_floating_window(source, target)

  if preview and vim.api.nvim_win_is_valid(preview.win) then
    pcall(vim.api.nvim_win_set_cursor, preview.win, util.lsp_pos_to_vim_cursor(target.pos))
  end
end

local function get_search_context(params)
  return params.textDocument.uri, params.position
end

local function open_or_pick_location(locations, label)
  vim.cmd("normal! m'")

  if #locations == 1 or config.select_first then
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

local function collect_client_locations(results)
  local all_locations = {}
  for client_id, res in pairs(results) do
    local client = vim.lsp.get_client_by_id(client_id)
    local client_name = client and client.name or "?"
    if not res.err and res.result then
      local items = vim.islist(res.result) and res.result or { res.result }
      for _, loc in ipairs(items) do
        loc.client_name = client_name
        table.insert(all_locations, loc)
      end
    end
  end
  return all_locations
end

local function peek_request(method, label)
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then
    vim.notify("No LSP client attached", vim.log.levels.WARN)
    return
  end

  local params = vim.lsp.util.make_position_params(0, "utf-16")

  vim.lsp.buf_request_all(0, method, params, function(results)
    if not results or vim.tbl_isempty(results) then
      vim.notify(("No %s found"):format(label), vim.log.levels.WARN)
      return
    end

    local all_locations = collect_client_locations(results)

    if #all_locations == 0 then
      vim.notify(("No %s found"):format(label), vim.log.levels.WARN)
      return
    end

    local search_uri, search_pos = get_search_context(params)
    local locations = util.filter_other_locations(all_locations, search_uri, search_pos)

    if #locations == 0 then
      vim.notify(("Already at %s"):format(label), vim.log.levels.WARN)
      return
    end

    open_or_pick_location(locations, label)
  end)
end

function M.peek_definition()
  peek_request("textDocument/definition", "definition")
end

function M.peek_type_definition()
  peek_request("textDocument/typeDefinition", "type definition")
end

return M
