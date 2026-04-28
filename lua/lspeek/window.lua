local M = {}

---Creates a floating preview window displaying the definition buffer
---@param buf integer Buffer number to display in the preview window
---@param filename string Filename to display in the window title
---@param row integer Line number to position the cursor (1-indexed)
---@param col integer Column number to position the cursor (0-indexed)
---@return integer win Window handle of the created preview window
function M.create_preview(buf, filename, row, col)
  local opts = require("lspeek.config").options

  ---@type vim.api.keyset.win_config
  local win_config = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = opts.window.width,
    height = opts.window.height,
    border = opts.window.border,
    title = filename,
    title_pos = opts.window.title_pos,
  }

  local win = vim.api.nvim_open_win(buf, opts.enter, win_config)

  -- Save original states
  local old_modifiable = vim.bo[buf].modifiable
  local old_winbar = vim.api.nvim_get_option_value("winbar", { win = win })
  local old_signcolumn = vim.api.nvim_get_option_value("signcolumn", { win = win })

  -- Set custom options for the peek window only
  vim.bo[buf].modifiable = false
  vim.api.nvim_set_option_value("winbar", "", { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })

  ---Removes all keymaps set by lspeek from the preview buffer
  ---@return nil
  local function cleanup_keymaps()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.keymap.del, "n", opts.keymaps.close, { buffer = buf })
      pcall(vim.keymap.del, "n", opts.keymaps.vsplit, { buffer = buf })
      pcall(vim.keymap.del, "n", opts.keymaps.split, { buffer = buf })
      pcall(vim.keymap.del, "n", opts.keymaps.enter, { buffer = buf })
    end
  end

  ---Restores original buffer and window options
  ---@return nil
  local function restore_state()
    vim.bo[buf].modifiable = old_modifiable
    vim.bo[buf].buflisted = true -- force
    vim.api.nvim_set_option_value("winbar", old_winbar, { win = win })
    vim.api.nvim_set_option_value("signcolumn", old_signcolumn, { win = win })
  end

  ---Closes the preview window and restores all original state
  ---@return nil
  local function close_and_restore()
    cleanup_keymaps()
    restore_state()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", opts.keymaps.close, function()
    close_and_restore()
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close LSPeek",
  })

  vim.keymap.set("n", opts.keymaps.vsplit, function()
    close_and_restore()
    vim.cmd("vsplit")
    vim.api.nvim_set_current_buf(buf)
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Vertical split",
  })

  vim.keymap.set("n", opts.keymaps.split, function()
    close_and_restore()
    vim.cmd("split")
    vim.api.nvim_set_current_buf(buf)
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Horizontal split",
  })

  vim.keymap.set("n", opts.keymaps.enter, function()
    local current_buf_name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t")
    if current_buf_name == filename then
      -- Same buffer - jump cursor to definition
      close_and_restore()
      vim.api.nvim_set_current_buf(buf)
      vim.api.nvim_win_set_cursor(0, { row, col })
    else
      -- Different buffer - open in edit mode
      close_and_restore()
      vim.cmd("edit")
      vim.api.nvim_set_current_buf(buf)
    end
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Open a new buffer",
  })

  vim.api.nvim_create_autocmd("WinClosed", {
    pattern = tostring(win),
    once = true,
    callback = function()
      if vim.api.nvim_buf_is_valid(buf) then
        close_and_restore()
      end
    end,
  })

  return win
end

return M
