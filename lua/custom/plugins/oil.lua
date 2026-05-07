-- Oil.nvim - file explorer as a buffer
-- See: https://github.com/stevearc/oil.nvim

vim.pack.add { 'https://github.com/stevearc/oil.nvim' }

require('oil').setup {
  -- Oil will take over directory buffers (e.g. `nvim .` or `:e .`)
  default_file_explorer = true,
  -- Delete the buffer corresponding to the file when moving/renaming
  delete_to_trash = false,
  -- Skip the confirmation popup when moving/renaming
  skip_confirm_for_simple_edits = false,
  -- Show file details (permissions, size) as virtual text
  view_options = {
    show_hidden = false,
    is_hidden_file = function(name, bufnr) return vim.startswith(name, '.') end,
  },
  -- Keymaps in oil buffer
  keymaps = {
    ['g?'] = 'actions.show_help',
    ['<CR>'] = 'actions.select',
    ['<C-v>'] = 'actions.select_vsplit',
    ['<C-s>'] = 'actions.select_split',
    ['<C-t>'] = 'actions.select_tab',
    ['<C-p>'] = 'actions.preview',
    ['<C-c>'] = 'actions.close',
    ['<C-l>'] = 'actions.refresh',
    ['-'] = 'actions.parent',
    ['_'] = 'actions.open_cwd',
    ['`'] = 'actions.cd',
    ['~'] = 'actions.tcd',
    ['gs'] = 'actions.change_sort',
    ['gx'] = 'actions.open_external',
    ['g.'] = 'actions.toggle_hidden',
    ['g\\'] = 'actions.toggle_trash',
  },
  -- Use these keymaps in the oil buffer
  use_default_keymaps = true,
}

-- Keymap to open oil in a floating window
vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Open parent directory (Oil)' })

-- Keymap to toggle hidden files in oil
vim.keymap.set('n', '<leader>e', '<cmd>Oil<CR>', { desc = '[E]xplore with Oil' })
