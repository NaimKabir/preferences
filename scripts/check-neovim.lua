assert(vim.v.errmsg == '', vim.v.errmsg)
assert(vim.o.relativenumber and not vim.o.number, 'Relative line numbers')
assert(vim.o.backup and vim.o.undofile and vim.o.hlsearch, 'Backup/undo/search')
assert(vim.fn.maparg('jk', 'i') == '<Esc>', 'Insert escape mapping')
assert(vim.fn.maparg('<C-P>', 'n') == '<Cmd>NvimTreeFindFile<CR>', 'File tree mapping')
assert(vim.fn.maparg('<C-Space>', 'n') == '<C-W>x', 'Exchange windows mapping')
assert(vim.fn.exists(':NvimTreeFindFile') == 2, 'NvimTree loaded')
assert(vim.fn.exists(':NERDTreeFind') == 0, 'NERDTree replaced in Neovim')
assert(vim.fn.exists(':DiffviewOpen') == 2, 'Diffview loaded')
assert(vim.g.loaded_airline == 1, 'Airline loaded')
assert(vim.fn.exists(':Black') == 2, 'Black command loaded')
for _, option in ipairs({ 'backupdir', 'directory', 'undodir' }) do
  assert(vim.fn.isdirectory(vim.opt[option]:get()[1]) == 1, option .. ' exists')
end
vim.cmd('edit ' .. vim.fn.fnameescape(vim.fn.tempname() .. '.lean'))
assert(vim.bo.filetype == 'lean', 'Lean file detection')
assert(vim.bo.shiftwidth == 2 and vim.bo.expandtab, 'Lean indentation')
vim.cmd.enew()
vim.bo.filetype = 'python'
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'x={"a":1}' })
vim.cmd.Black()
assert(vim.api.nvim_get_current_line() == 'x = {"a": 1}', 'Python formatting')
local tick = vim.b.changedtick
vim.cmd.Black()
assert(vim.b.changedtick == tick, 'Already formatted buffer unchanged')
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'def invalid(' })
assert(not pcall(vim.cmd.Black), 'Invalid Python rejected')
assert(vim.api.nvim_get_current_line() == 'def invalid(', 'Failed format preserves buffer')

assert(vim.fn.exists(':Prettier') == 2, 'Prettier command loaded')
local project = vim.fn.tempname() .. ' prettier project'
vim.fn.mkdir(project, 'p')
vim.fn.writefile({ '{"singleQuote":true,"semi":false}' }, project .. '/.prettierrc.json')
local ok, err = pcall(function()
  for _, case in ipairs({
    { 'js', 'const value={name:"hello"}', "const value = { name: 'hello' }" },
    { 'ts', 'const value:number=1', 'const value: number = 1' },
    { 'jsx', 'const view=<div name="hello"/>', 'const view = <div name="hello" />' },
    { 'tsx', 'const view: JSX.Element=<div/>', 'const view: JSX.Element = <div />' },
  }) do
    vim.cmd('enew!')
    local filename = project .. '/example.' .. case[1]
    vim.api.nvim_buf_set_name(0, filename)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { case[2] })
    vim.cmd.Prettier()
    assert(vim.api.nvim_get_current_line() == case[3], case[1] .. ' formatting with project config: ' .. vim.inspect(vim.api.nvim_buf_get_lines(0, 0, -1, false)))
    assert(vim.fn.filereadable(filename) == 0, 'Formatting must not save the file')
    tick = vim.b.changedtick
    vim.cmd.Prettier()
    assert(vim.b.changedtick == tick, 'Already formatted buffer unchanged')
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'const broken = {' })
  assert(not pcall(vim.cmd.Prettier), 'Invalid TypeScript rejected')
  assert(vim.api.nvim_get_current_line() == 'const broken = {', 'Failed Prettier preserves buffer')
  vim.fn.writefile({ 'ignored.ts' }, project .. '/.prettierignore')
  vim.cmd('enew!')
  vim.api.nvim_buf_set_name(0, project .. '/ignored.ts')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'const value:number=1' })
  vim.cmd.Prettier()
  assert(vim.api.nvim_get_current_line() == 'const value:number=1', 'Project ignore rules respected')
  vim.cmd('enew!')
  vim.bo.filetype = 'typescript'
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'const value:number=1' })
  vim.cmd.Prettier()
  assert(vim.api.nvim_get_current_line():match('^const value: number = 1'), 'Unnamed TypeScript buffer')
end)
vim.fn.delete(project, 'rf')
assert(ok, err)
print('Neovim preferences checks passed')
