local project = vim.fn.tempname() .. ' git project'
vim.fn.mkdir(project, 'p')
project = vim.uv.fs_realpath(project)
local function git(...)
  local cmd = { 'git', '-C', project }
  vim.list_extend(cmd, { ... })
  local result = vim.system(cmd, { text = true }):wait()
  assert(result.code == 0, result.stderr)
end
local function write(name, text)
  vim.fn.writefile({ text }, project .. '/' .. name)
end
local ok, err = pcall(function()
  git('init', '--quiet')
  write('modified.txt', 'original')
  write('staged.txt', 'original')
  git('add', '.')
  git('-c', 'user.name=Preferences Test', '-c', 'user.email=test@example.invalid',
    '-c', 'commit.gpgsign=false', 'commit', '--quiet', '-m', 'fixture')
  write('modified.txt', 'unstaged change')
  write('staged.txt', 'staged change')
  git('add', 'staged.txt')
  write('untracked.txt', 'new file')
  vim.cmd.cd(vim.fn.fnameescape(project))
  vim.cmd.edit('modified.txt')
  local tree = require('nvim-tree.api')
  tree.tree.open({ path = project })
  local buffer = vim.api.nvim_get_current_buf()
  assert(vim.bo[buffer].filetype == 'NvimTree', 'Tree opened')
  assert(vim.wait(10000, function()
    local text = table.concat(vim.api.nvim_buf_get_lines(buffer, 0, -1, false), '\n')
    return text:match('M%s+modified.txt') and text:match('S%s+staged.txt') and text:match('%?%s+untracked.txt')
  end, 100), 'Tree did not display modified/staged/untracked status')
  assert(vim.fn.maparg('s', 'n', false, true).desc == 'Open in vertical split', 'Tree split mapping')
  tree.tree.close()
  vim.cmd.DiffviewOpen()
  assert(vim.wait(10000, function()
    local view = require('diffview.lib').get_current_view()
    return view and view.files and #view.files.working == 2 and #view.files.staged == 1
  end, 100), 'Diffview did not show staged and unstaged changes')
  assert(vim.wait(10000, function()
    local contents = {}
    for _, window in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.wo[window].diff then
        local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(window), 0, -1, false)
        contents[table.concat(lines, '\n')] = true
      end
    end
    return contents.original and contents['unstaged change']
  end, 100), 'Diff buffers did not render original and changed content')
  vim.cmd.DiffviewClose()
  assert(not require('diffview.lib').get_current_view(), 'Diffview closed')
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print('Git tree status and diff inspection checks passed')
end)
vim.cmd('cd ' .. vim.fn.fnameescape(vim.fn.expand('~')))
vim.fn.delete(project, 'rf')
assert(ok, err)
