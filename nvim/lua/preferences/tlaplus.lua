local directory = vim.fn.stdpath('data') .. '/preferences-tlaplus'
-- The separate symbol-entry plugin reads this flag when opening .tla buffers.
vim.g.tlaplus_mappings_enable = true
vim.opt.runtimepath:prepend(directory)
vim.filetype.add({ extension = { tla = 'tla' } })
vim.treesitter.language.register('tlaplus', 'tla')

local server = vim.env.TLAPM_LSP or directory .. '/tlapm/bin/tlapm_lsp'
if vim.fn.executable(server) == 0 and not vim.env.TLAPM_LSP then
  server = vim.fn.exepath('tlapm_lsp')
end
local installed = vim.fn.executable(server) == 1
if installed then
  vim.lsp.config('preferences_tlaplus', {
    cmd = { server, '--stdio' },
    filetypes = { 'tla' },
    root_markers = { '.git' },
    init_options = { moduleSearchPaths = {} },
  })
  vim.lsp.enable('preferences_tlaplus')
end

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'tla',
  group = vim.api.nvim_create_augroup('PreferencesTla', { clear = true }),
  callback = function(event)
    vim.bo[event.buf].commentstring = [[\* %s]]
    local ok = pcall(vim.treesitter.start, event.buf, 'tlaplus')
    if not ok or not installed then
      vim.notify('TLA+ support is incomplete; run ./setup-tlaplus.sh in the preferences repo.', vim.log.levels.WARN)
    end
  end,
})
