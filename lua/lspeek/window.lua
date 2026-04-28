local M = {}

function M.create_preview(buf, filename, row, col)
  local opts = require("lspeek.config").options

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = opts.window.width,
    height = opts.window.height,
    border = opts.window.border,
    title = filename,
    title_pos = "center",
  }

  local win = vim.api.nvim_open_win(buf, opts.enter, win_config)

  -- Save original states
  local old_modifiable = vim.bo[buf].modifiable
  local old_buflisted = vim.bo[buf].buflisted
  local old_winbar = vim.api.nvim_get_option_value("winbar", { win = win })
  local old_signcolumn = vim.api.nvim_get_option_value("signcolumn", { win = win })

  -- Set custom options for the peek window only
  vim.bo[buf].modifiable = false
  vim.bo[buf].buflisted = false
  vim.api.nvim_set_option_value("winbar", "", { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })

  local function cleanup_keymaps()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.keymap.del, "n", opts.keymaps.close, { buffer = buf })
      pcall(vim.keymap.del, "n", "v", { buffer = buf })
      pcall(vim.keymap.del, "n", "s", { buffer = buf })
      pcall(vim.keymap.del, "n", "<CR>", { buffer = buf })
    end
  end

  local function restore_state()
    vim.bo[buf].modifiable = old_modifiable
    vim.bo[buf].buflisted = old_buflisted
    vim.bo[buf].buflisted = true -- force
    vim.api.nvim_set_option_value("winbar", old_winbar, { win = win })
    vim.api.nvim_set_option_value("signcolumn", old_signcolumn, { win = win })
  end

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

  vim.keymap.set("n", "v", function()
    close_and_restore()
    vim.cmd("vsplit")
    vim.api.nvim_set_current_buf(buf)
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Vertiable split",
  })

  vim.keymap.set("n", "s", function()
    close_and_restore()
    vim.cmd("split")
    vim.api.nvim_set_current_buf(buf)
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Horizontal split",
  })

  vim.keymap.set("n", "<CR>", function()
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
