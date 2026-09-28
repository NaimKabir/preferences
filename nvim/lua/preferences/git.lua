local function normalize(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ':p'))
end

-- Hide anything the arglist doesn't name, so `:args a b` narrows the tree to
-- those files. A directory arg keeps its whole subtree, which makes `nvim .`
-- show everything. Clear the arglist (`\ac`) to show everything again.
local function hidden_by_arglist(path)
  local args = vim.fn.argv()
  if #args == 0 then return false end
  path = normalize(path)
  for _, arg in ipairs(args) do
    local argpath = normalize(arg)
    if path == argpath
      or vim.startswith(argpath, path .. '/') -- path is an ancestor of the arg
      or vim.startswith(path, argpath .. '/') -- path is inside a directory arg
    then
      return false
    end
  end
  return true
end

require('nvim-tree').setup({
  hijack_netrw = false, -- netrw is already disabled in init.lua
  git = { enable = true, show_on_dirs = true },
  filters = { git_ignored = true, dotfiles = false, custom = hidden_by_arglist },
  renderer = {
    highlight_git = 'all',
    icons = {
      -- Readable without installing a Nerd Font.
      show = { file = false, folder = false, git = true, bookmarks = false },
      glyphs = {
        folder = { arrow_closed = '>', arrow_open = 'v' },
        git = { unstaged = 'M', staged = 'S', unmerged = 'U', renamed = 'R',
          untracked = '?', deleted = 'D', ignored = 'I' },
      },
    },
  },
  on_attach = function(buffer)
    local api = require('nvim-tree.api')
    api.map.on_attach.default(buffer)
    local function map(key, action, description)
      vim.keymap.set('n', key, action, { buffer = buffer, silent = true, desc = description })
    end
    -- Retain the familiar NERDTree open keys and custom split navigation.
    map('s', api.node.open.vertical, 'Open in vertical split')
    map('i', api.node.open.horizontal, 'Open in horizontal split')
    map('t', api.node.open.tab, 'Open in new tab')
    map('<C-k>', '<C-w>k', 'Move to window above')
  end,
})

vim.keymap.set('n', '<C-P>', '<Cmd>NvimTreeFindFile<CR>', { desc = 'Reveal file in tree' })
vim.keymap.set('n', '<leader>n', '<Cmd>NvimTreeToggle<CR>', { desc = 'Toggle file tree' })

-- Neovim has no arglist-changed event, but every change goes through the
-- command line, so re-check after each command and redraw the tree if needed.
local last_args = vim.fn.argv()
vim.api.nvim_create_autocmd('CmdlineLeave', {
  group = vim.api.nvim_create_augroup('PreferencesArglistTree', { clear = true }),
  callback = function()
    vim.schedule(function()
      local args = vim.fn.argv()
      if not vim.deep_equal(args, last_args) then
        last_args = args
        require('nvim-tree.api').tree.reload()
      end
    end)
  end,
})
vim.keymap.set('n', '<leader>aa', '<Cmd>argadd %<CR>', { desc = 'Add current file to arglist' })
vim.keymap.set('n', '<leader>ac', '<Cmd>%argdelete<CR>', { desc = 'Clear arglist' })

local close = { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close diff view' } }
require('diffview').setup({
  use_icons = false,
  signs = { fold_closed = '>', fold_open = 'v', done = '+' },
  keymaps = { view = { close }, file_panel = { close }, file_history_panel = { close } },
  hooks = {
    -- Diff windows default to `foldmethod=diff` with all folds closed, which
    -- hides unchanged context. Show every line instead.
    diff_buf_win_enter = function()
      vim.opt_local.foldenable = false
      vim.opt_local.foldcolumn = '0'
    end,
  },
})
vim.keymap.set('n', '<leader>gd', '<Cmd>DiffviewOpen<CR>', { desc = 'Inspect working-tree changes' })
vim.keymap.set('n', '<leader>gs', '<Cmd>DiffviewOpen --cached<CR>', { desc = 'Inspect staged changes' })
vim.keymap.set('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'Inspect current file history' })
vim.keymap.set('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = 'Close diff view' })
