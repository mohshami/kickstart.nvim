-- Enable spellcheck for specific filetypes
-- Customize this list to add/remove filetypes where spellcheck is active

local spellcheck_filetypes = {
  'markdown',
  'text',
  'gitcommit',
  'tex',
  'nix',
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = spellcheck_filetypes,
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.spelllang = 'en_us'
  end,
})
