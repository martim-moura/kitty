-- Sourced by kitty's scrollback_pager (see kitty.conf).
--
-- kitty pipes the scrollback into nvim on stdin. The classic recipe renders it
-- with nvim_open_term() so ANSI colors survive, but that makes the buffer a
-- 'terminal' buffer, which nvim never lets you edit or :write.
--
-- So: render into the terminal buffer first (colors), then on demand copy the
-- plain text into a normal scratch buffer that is editable and writable.
--
--   E   copy current scrollback into an editable scratch buffer
--   q   quit without saving
--
-- After pressing E:  :w ~/somewhere.txt

local channel = vim.api.nvim_open_term(0, {})

local function to_editable()
  if vim.bo.buftype ~= 'terminal' then
    vim.notify('already editable', vim.log.levels.INFO)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- kitty pads the terminal buffer out to the window height; drop that padding
  while #lines > 0 and lines[#lines]:match('^%s*$') do
    table.remove(lines)
  end

  vim.fn.chanclose(channel)
  vim.cmd('enew')                 -- normal, modifiable, no buftype
  vim.bo.swapfile = false
  vim.bo.bufhidden = 'wipe'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.modified = false
  vim.cmd('normal! G')
  vim.notify('editable copy - :w <file> to save')
end

vim.keymap.set('n', 'E', to_editable, { desc = 'editable copy of scrollback' })
vim.api.nvim_create_user_command('Editable', to_editable, {})

vim.keymap.set('n', 'q', '<cmd>qa!<cr>', { desc = 'quit pager' })

vim.schedule(function()
  vim.bo.modified = false
  vim.opt.list = false
  vim.cmd('normal! G')
end)
