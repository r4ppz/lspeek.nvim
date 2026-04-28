local config = require("lspeek.config")
local M = {}

function M.create_preview(buf)
  local opts = config.options

  local win_config = {
    relative = "cursor",
    row = 1,
    col = 1,
    width = opts.window.width,
    height = opts.window.height,
    border = opts.window.border,
  }
  local win = vim.api.nvim_open_win(buf, opts.enter, win_config)

  -- Original states
  local was_modifiable = vim.bo[buf].modifiable
  local was_buflisted = vim.bo[buf].buflisted
  vim.bo[buf].modifiable = false

  local old_winbar = vim.api.nvim_get_option_value("winbar", { win = win })
  local old_signcolumn = vim.api.nvim_get_option_value("signcolumn", { win = win })

  vim.api.nvim_set_option_value("winbar", "", { win = win })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = win })

  local function cleanup()
    if vim.api.nvim_buf_is_valid(buf) then
      pcall(vim.keymap.del, "n", opts.keymaps.close, { buffer = buf })
      pcall(vim.keymap.del, "n", "v", { buffer = buf })
      pcall(vim.keymap.del, "n", "s", { buffer = buf })
      pcall(vim.keymap.del, "n", "<CR>", { buffer = buf })
    end
  end

  local function transition(command)
    cleanup()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_option_value("winbar", old_winbar, { win = win })
      vim.api.nvim_set_option_value("signcolumn", old_signcolumn, { win = win })
      vim.api.nvim_win_close(win, true)
    end

    vim.bo[buf].modifiable = true
    vim.bo[buf].buflisted = true

    if command then
      if command ~= "edit" then
        vim.cmd(command)
      end
      vim.api.nvim_set_current_buf(buf)
    end
  end

  vim.keymap.set("n", opts.keymaps.close, function()
    transition(nil)
    vim.bo[buf].modifiable = was_modifiable
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Close LSPeek",
  })

  vim.keymap.set("n", "v", function()
    transition("vsplit")
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Vertiable split",
  })

  vim.keymap.set("n", "s", function()
    transition("split")
  end, {
    buffer = buf,
    silent = true,
    nowait = true,
    desc = "Horizontal split",
  })

  vim.keymap.set("n", "<CR>", function()
    transition("edit")
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
      cleanup()
      if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_get_current_win() ~= win then
        vim.bo[buf].modifiable = was_modifiable
        vim.bo[buf].buflisted = was_buflisted
      end
    end,
  })

  return win
end

return M
