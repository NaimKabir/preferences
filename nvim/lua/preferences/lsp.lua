-- Neovim provides the client; setup-neovim.sh installs the pinned servers.
local bin = vim.fn.stdpath('data') .. '/preferences-lsp/node_modules/.bin/'
-- This pinned Airline predates vim.diagnostic; use Neovim's diagnostics UI.
vim.g['airline#extensions#nvimlsp#enabled'] = 0

vim.lsp.config('preferences_typescript', {
  cmd = { bin .. 'typescript-language-server', '--stdio' },
  filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  root_markers = { { 'tsconfig.json', 'jsconfig.json', 'package.json' }, '.git' },
})

vim.lsp.config('preferences_python', {
  cmd = { bin .. 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', 'requirements.txt' }, '.git' },
  settings = { python = { analysis = { diagnosticMode = 'openFiles' } } },
  before_init = function(_, config)
    -- Prefer the project's usual venv, then an activated venv, then PATH.
    local candidates = {
      (config.root_dir or vim.fn.getcwd()) .. '/.venv/bin/python',
    }
    if vim.env.VIRTUAL_ENV then table.insert(candidates, vim.env.VIRTUAL_ENV .. '/bin/python') end
    table.insert(candidates, vim.fn.exepath('python3'))
    for _, python in ipairs(candidates) do
      if vim.fn.executable(python) == 1 then
        config.settings.python.pythonPath = python
        break
      end
    end
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('PreferencesLsp', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    local function map(key, action, description, method)
      if method and not client:supports_method(method) then return end
      vim.keymap.set('n', key, action, { buffer = event.buf, desc = description })
    end
    map('gd', vim.lsp.buf.definition, 'Go to definition', 'textDocument/definition')
    map('grr', vim.lsp.buf.references, 'Find references', 'textDocument/references')
    map('gri', vim.lsp.buf.implementation, 'Find implementations', 'textDocument/implementation')
    map('grt', vim.lsp.buf.type_definition, 'Go to type definition', 'textDocument/typeDefinition')
    map('grn', vim.lsp.buf.rename, 'Rename symbol', 'textDocument/rename')
    map('gra', vim.lsp.buf.code_action, 'Code actions', 'textDocument/codeAction')
    map('K', vim.lsp.buf.hover, 'Documentation and type', 'textDocument/hover')
    map('<leader>ci', vim.lsp.buf.incoming_calls, 'Find callers', 'textDocument/prepareCallHierarchy')
    map('<leader>co', vim.lsp.buf.outgoing_calls, 'Find called functions', 'textDocument/prepareCallHierarchy')
    map('<leader>e', vim.diagnostic.open_float, 'Show diagnostic')
  end,
})

vim.lsp.enable({ 'preferences_typescript', 'preferences_python' })
