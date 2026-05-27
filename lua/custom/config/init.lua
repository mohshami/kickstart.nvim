require 'custom/config/spell'
require 'custom/config/options'
require 'custom/config/keymaps'
require 'custom/config/vault'
require('custom/config/sops').setup()

vim.g.have_nerd_font = true
vim.cmd.colorscheme 'tokyonight-night'
