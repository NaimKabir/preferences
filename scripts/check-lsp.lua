-- Integration checks against the installed servers, using disposable projects.
local project = vim.fn.tempname() .. ' lsp project'
vim.fn.mkdir(project, 'p')
project = vim.uv.fs_realpath(project)
local function write(name, lines)
  vim.fn.writefile(lines, project .. '/' .. name)
end
local function request(client, method, params, buffer)
  local response, err = client:request_sync(method, params, 15000, buffer)
  assert(response, method .. ': ' .. tostring(err))
  assert(not response.err, method .. ': ' .. vim.inspect(response.err))
  return response.result
end
local ok, err = pcall(function()
  for _, language in ipairs({ 'typescript', 'python' }) do
    local ts = language == 'typescript'
    local extension = ts and 'ts' or 'py'
    if ts then
      write('tsconfig.json', { '{"compilerOptions":{"strict":true},"include":["*.ts"]}' })
      write('lib.ts', { 'export function greet(name: string) {', '  return name;', '}' })
      write('main.ts', { 'import { greet } from "./lib";', 'export function caller() {', '  return greet("world");', '}', 'caller();' })
    else
      write('pyrightconfig.json', { '{"include":["*.py"]}' })
      write('lib.py', { 'def greet(name):', '    return name' })
      write('main.py', { 'from lib import greet', 'def caller():', '    return greet("world")', 'caller()' })
    end
    local main = project .. '/main.' .. extension
    local library = project .. '/lib.' .. extension
    vim.cmd('edit ' .. vim.fn.fnameescape(main))
    local buffer = vim.api.nvim_get_current_buf()
    local client
    assert(vim.wait(15000, function()
      client = vim.lsp.get_clients({ bufnr = buffer, name = 'preferences_' .. language })[1]
      return client and client.initialized
    end, 50), language .. ' server did not attach')
    assert(vim.fn.maparg('gd', 'n', false, true).buffer == 1, 'Definition shortcut attached')
    assert(vim.fn.maparg('<leader>ci', 'n', false, true).buffer == 1, 'Caller shortcut attached')
    local position = { textDocument = { uri = vim.uri_from_fname(main) }, position = { line = 2, character = ts and 10 or 12 } }
    -- Attachment precedes initial project indexing; wait for imported symbols.
    assert(vim.wait(15000, function()
      local definitions = request(client, 'textDocument/definition', position, buffer)
      return definitions and #definitions > 0
        and (definitions[1].uri or definitions[1].targetUri) == vim.uri_from_fname(library)
    end, 200), language .. ' cross-file definition missing after indexing')
    local references = request(client, 'textDocument/references', vim.tbl_extend('force', position, { context = { includeDeclaration = true } }), buffer)
    assert(references and #references >= 2, language .. ' references missing')
    local items = request(client, 'textDocument/prepareCallHierarchy', position, buffer)
    assert(items and #items > 0, language .. ' call hierarchy missing')
    local incoming = request(client, 'callHierarchy/incomingCalls', { item = items[1] }, buffer)
    assert(incoming and #incoming > 0 and incoming[1].from.name == 'caller', language .. ' callers missing: ' .. vim.inspect(incoming))
    local outgoing = request(client, 'callHierarchy/outgoingCalls', { item = incoming[1].from }, buffer)
    assert(outgoing and #outgoing > 0 and outgoing[1].to.name == 'greet', language .. ' outgoing calls missing')
    assert(vim.v.errmsg == '', vim.v.errmsg)
    print(language .. ': definition, references, callers passed')
  end
end)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
vim.fn.delete(project, 'rf')
assert(ok, err)
