local M = {}

local default_opts = {
  window = {
    width = 70,
    height = 15,
    border = "single",
  },

  enter = true,

  keymaps = {
    close = "q",
  },
}

M.config = {}

M.setup = function(user_opts)
  M.config = vim.tbl_deep_extend("force", default_opts, user_opts or {})
end

function M.preview_definition()
  local params = vim.lsp.util.make_position_params(0, "utf-16")

  local function callback(err, result, clx, _)
    if err then
      vim.notify("LSP Error: " .. err.message, vim.log.levels.ERROR)
    end

    if not result or vim.tbl_isempty(result) then
      vim.notify("No definition found", vim.log.levels.WARN)
    end

    local location = vim.islist(result) and result[1] or result

    local target_buf = vim.uri_to_bufnr(location.uri or location.targetUri)
    if not vim.api.nvim_buf_is_loaded(target_buf) then
      vim.fn.bufload(target_buf)
    end

    local win = M.create_floating_window(target_buf)

    local range = location.range or location.targetSelectionRange
    if range then
      local row = range.start.line + 1
      local col = range.start.character
      vim.api.nvim_win_set_cursor(win, { row, col })
    end
  end

  vim.lsp.buf_request(0, "textDocument/definition", params, callback)
end

function M.create_floating_window(buf, local_opts)
  buf = buf or vim.api.nvim_get_current_buf()

  local config = vim.tbl_deep_extend("force", M.config, local_opts or {})

  if not vim.api.nvim_buf_is_valid(buf) then
    error("Invalid buffer")
  end

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = config.window.width,
    height = config.window.height,
    border = config.window.border,
  }

  vim.keymap.set("n", config.keymaps.close, "<cmd>close<cr>", {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close Sight Window",
  })

  local buf_options = {
    modifiable = false,
    readonly = true,
    bufhidden = "wipe",
  }

  for opt, val in pairs(buf_options) do
    vim.api.nvim_set_option_value(opt, val, { buf = buf })
  end

  local win = vim.api.nvim_open_win(buf, config.enter, win_config)
  return win
end

return M
