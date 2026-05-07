local vault_augroup = vim.api.nvim_create_augroup('ansible-vault', { clear = true })

vim.api.nvim_create_autocmd('BufReadCmd', {
  group = vault_augroup,
  pattern = { '*.vault.yml', '*.vault.yaml' },
  callback = function(args)
    local fname = vim.fn.expand '<afile>'
    local buf = args.buf

    -- New file: nothing to read, just set filetype
    if vim.fn.filereadable(fname) == 0 then
      vim.bo[buf].filetype = 'yaml.ansible'
      return
    end

    -- Try ansible-vault decryption first; on failure read as plain text
    local output = vim.fn.system { 'ansible-vault', 'decrypt', '--output', '-', fname }
    local ok = vim.v.shell_error == 0

    if ok then
      local lines = vim.split(output, '\n', { plain = true })
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    else
      -- File is not encrypted (or another error): read normally
      local lines = vim.fn.readfile(fname)
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end

    vim.bo[buf].modified = false
    vim.bo[buf].filetype = 'yaml.ansible'
  end,
})

vim.api.nvim_create_autocmd('BufWriteCmd', {
  group = vault_augroup,
  pattern = { '*.vault.yml', '*.vault.yaml' },
  callback = function(args)
    local fname = vim.fn.expand '<afile>'
    local buf = args.buf

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local content = table.concat(lines, '\n')

    -- Write plain content to a temp file, then encrypt in place to the real target
    local tmpfile = vim.fn.tempname()
    vim.fn.writefile(vim.split(content, '\n'), tmpfile)

    vim.fn.system { 'ansible-vault', 'encrypt', '--output', fname, tmpfile }
    local ok = vim.v.shell_error == 0

    vim.fn.delete(tmpfile)

    if ok then
      vim.bo[buf].modified = false
      vim.api.nvim_echo({ { 'ansible-vault: encrypted and saved', 'Normal' } }, false, {})
    else
      vim.api.nvim_echo({ { 'ansible-vault encrypt failed!', 'ErrorMsg' } }, true, {})
    end
  end,
})
