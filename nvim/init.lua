-- Resolve the symlink so the checkout can live anywhere (including paths with spaces).
local init = vim.fn.resolve(debug.getinfo(1, 'S').source:sub(2))
local repo = vim.fn.fnamemodify(init, ':h:h')

-- Reuse the pinned Vim plugins, excluding the legacy Python-host Black plugin.
for _, plugin in ipairs({ 'airline', 'lean' }) do
  vim.opt.runtimepath:prepend(repo .. '/vim/pack/plugins/start/' .. plugin)
end
for _, plugin in ipairs({ 'plenary', 'nvim-tree', 'diffview', 'nightfox' }) do
  vim.opt.runtimepath:prepend(repo .. '/nvim/plugins/' .. plugin)
end
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.cmd('source ' .. vim.fn.fnameescape(repo .. '/vimrc'))

-- The Vim defaults.vim settings that aren't already Neovim defaults.
vim.opt.scrolloff = 5
vim.opt.mouse = 'a'
vim.opt.ttimeoutlen = 100
vim.opt.termguicolors = true
vim.opt.laststatus = 2
vim.cmd.colorscheme('dayfox')
vim.keymap.set({ 'n', 'x' }, 'Q', 'gq')
vim.keymap.set('i', '<C-U>', '<C-G>u<C-U>')
vim.cmd('filetype plugin indent on')
vim.cmd('syntax enable')

local group = vim.api.nvim_create_augroup('Preferences', { clear = true })
vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  callback = function()
    local line = vim.fn.line("'\"")
    if line >= 1 and line <= vim.fn.line('$') and not vim.wo.diff
      and not vim.bo.filetype:match('commit')
      and not vim.tbl_contains({ 'xxd', 'gitrebase', 'tutor' }, vim.bo.filetype) then
      vim.cmd([[normal! g`"]])
    end
  end,
})

-- Keep recovery files out of the checkout, with separate dirs and full-path names.
for option, directory in pairs({ backupdir = 'backup', directory = 'swap', undodir = 'undo' }) do
  local path = vim.fn.stdpath('state') .. '/' .. directory
  vim.fn.mkdir(path, 'p', '0700')
  vim.opt[option] = { path .. '//' }
end

-- Format via stdin; don't save the buffer or replace it when a formatter fails.
local function format_buffer(command, cwd)
  local input = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n') .. '\n'
  local result = vim.system(command, {
    stdin = input, text = true, cwd = cwd,
  }):wait()
  if result.code ~= 0 then error(result.stderr) end
  if result.stdout ~= input then
    local view = vim.fn.winsaveview()
    local lines = vim.split(result.stdout:gsub('\n$', ''), '\n', { plain = true })
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.fn.winrestview(view)
  end
end

vim.api.nvim_create_user_command('Black', function()
  local black = vim.fn.stdpath('data') .. '/preferences-black/bin/black'
  if vim.fn.executable(black) == 0 then
    error('Black is missing; rerun setup-neovim.sh')
  end
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == '' then filename = vim.fn.getcwd() .. '/untitled.py' end
  format_buffer({ black, '--quiet', '--stdin-filename', filename, '-' })
end, { desc = 'Format the current Python buffer with Black' })

vim.api.nvim_create_user_command('Prettier', function()
  local prettier = vim.fn.stdpath('data') .. '/preferences-prettier/node_modules/.bin/prettier'
  if vim.fn.executable(prettier) == 0 or vim.fn.executable('node') == 0 then
    error('Prettier or Node.js is missing; rerun setup-neovim.sh and check your PATH')
  end
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == '' then
    local extension = ({ javascript = 'js', javascriptreact = 'jsx',
      typescript = 'ts', typescriptreact = 'tsx' })[vim.bo.filetype]
    if not extension then error('Save the buffer with a filename or set its JavaScript/TypeScript filetype') end
    filename = vim.fn.getcwd() .. '/untitled.' .. extension
  end
  -- Resolve ignores and plugins from the file's project, even when Neovim was
  -- launched elsewhere. For a new nested path, start at an existing ancestor.
  local directory = vim.fs.dirname(filename)
  while vim.fn.isdirectory(directory) == 0 do
    directory = vim.fs.dirname(directory)
  end
  local marker = vim.fs.find({ '.prettierignore', 'package.json', '.git' }, {
    path = directory, upward = true,
  })[1]
  local cwd = marker and vim.fs.dirname(marker) or directory
  format_buffer({ prettier, '--stdin-filepath', filename }, cwd)
end, { desc = 'Format the current buffer with Prettier' })

require('preferences.lsp')
require('preferences.git')
