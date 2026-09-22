require('nvim-tree').setup({
  hijack_netrw = false, -- netrw is already disabled in init.lua
  git = { enable = true, show_on_dirs = true },
  filters = { git_ignored = true, dotfiles = false },
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

local close = { 'n', 'q', '<Cmd>DiffviewClose<CR>', { desc = 'Close diff view' } }
require('diffview').setup({
  use_icons = false,
  signs = { fold_closed = '>', fold_open = 'v', done = '+' },
  keymaps = { view = { close }, file_panel = { close }, file_history_panel = { close } },
})
vim.keymap.set('n', '<leader>gd', '<Cmd>DiffviewOpen<CR>', { desc = 'Inspect working-tree changes' })
vim.keymap.set('n', '<leader>gs', '<Cmd>DiffviewOpen --cached<CR>', { desc = 'Inspect staged changes' })
vim.keymap.set('n', '<leader>gh', '<Cmd>DiffviewFileHistory %<CR>', { desc = 'Inspect current file history' })
vim.keymap.set('n', '<leader>gq', '<Cmd>DiffviewClose<CR>', { desc = 'Close diff view' })
