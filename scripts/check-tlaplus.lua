local project = vim.fn.tempname() .. ' tla project'
vim.fn.mkdir(project, 'p')
project = vim.uv.fs_realpath(project)
local filename = project .. '/Counter.tla'
vim.fn.writefile({
  '---- MODULE Counter ----',
  'EXTENDS Naturals',
  'VARIABLE x',
  'Init == x = 0',
  "Next == x' = x + 1",
  '====',
}, filename)
local ok, err = pcall(function()
  vim.cmd.edit(vim.fn.fnameescape(filename))
  local buffer = vim.api.nvim_get_current_buf()
  assert(vim.bo.filetype == 'tla', 'TLA+ file detection')
  assert(vim.b.tlaplus_mappings_defined, 'Unicode input mappings enabled')
  -- Exercise typed input, including overlapping mappings, then restore the spec.
  vim.api.nvim_buf_set_lines(buffer, 3, 4, false, { '' })
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  local keys = vim.api.nvim_replace_termcodes('i\\A \\leq <=> <Esc>', true, false, true)
  vim.api.nvim_feedkeys(keys, 'xt', false)
  assert(vim.api.nvim_get_current_line() == '∀ ≤ ⇔ ', 'Typed ASCII converts to Unicode')
  vim.cmd.TlaMappingsRemove()
  assert(vim.fn.maparg('\\A', 'i') == '', 'Unicode input can be disabled per buffer')
  vim.cmd.TlaMappingsAdd()
  vim.api.nvim_buf_set_lines(buffer, 3, 4, false, { 'Init == x = 0' })
  local parser = vim.treesitter.get_parser(buffer, 'tlaplus')
  assert(not parser:parse()[1]:root():has_error(), 'TLA+ parser')
  assert(vim.treesitter.highlighter.active[buffer], 'TLA+ syntax highlighting active')
  local query = vim.treesitter.query.get('tlaplus', 'highlights')
  local highlighted = false
  for id in query:iter_captures(parser:parse()[1]:root(), buffer, 0, -1) do
    if query.captures[id] == 'keyword' then highlighted = true end
  end
  assert(highlighted, 'TLA+ keywords highlighted')
  local pluscal = vim.treesitter.get_string_parser([[
---- MODULE Algorithm ----
EXTENDS Naturals
(* --algorithm Counter
variables x = 0;
begin
  Loop: while x < 2 do
    x := x + 1;
  end while;
end algorithm; *)
====
]], 'tlaplus')
  assert(not pluscal:parse()[1]:root():has_error(), 'Embedded PlusCal parser')
  local client
  assert(vim.wait(15000, function()
    client = vim.lsp.get_clients({ bufnr = buffer, name = 'preferences_tlaplus' })[1]
    return client and client.initialized
  end, 50), 'TLA+ server did not attach')
  assert(client:supports_method('textDocument/codeAction'), 'Proof code actions supported')
  assert(client:supports_method('textDocument/rename'), 'Proof-step rename supported')
  assert(not client:supports_method('textDocument/definition'), 'Documented navigation limitation')
  vim.api.nvim_buf_set_lines(buffer, 3, 4, false, { 'Init == )' })
  assert(vim.wait(15000, function()
    -- TLAPM currently reports some parse errors with warning severity.
    for _, diagnostic in ipairs(vim.diagnostic.get(buffer)) do
      if diagnostic.lnum == 3 and diagnostic.message:match('missing') then return true end
    end
    return false
  end, 100), 'TLA+ syntax error diagnostics missing')
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print('TLA+ highlighting, server attachment, and error diagnostics passed')
end)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.fn.delete(project, 'rf')
assert(ok, err)
