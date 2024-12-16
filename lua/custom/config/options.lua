vim.opt.relativenumber = true
vim.opt.clipboard = ''
-- This needs to be set in init.lua
vim.g.have_nerd_font = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.colorcolumn = '80'
vim.opt.cursorline = true

vim.api.nvim_create_autocmd("FileType", {
    pattern = "nix",
    callback = function()
        vim.opt_local.shiftwidth = 2
        vim.opt_local.tabstop = 2
    end
})
