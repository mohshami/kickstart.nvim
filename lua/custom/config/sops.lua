local M = {}

M.defaults = {
  patterns = { '*.enc.yml', '*.enc.yaml', '*.enc.json', 'secrets.yaml' },
  -- mapping from last file extension to Neovim filetype
  ft_map = {
    yml = 'yaml',
    yaml = 'yaml',
    json = 'json',
  },
}

M.config = M.defaults

---@param opts? table<string, any>
function M.setup(opts)
  M.config = vim.tbl_deep_extend('force', M.defaults, opts or {})

  local augroup = vim.api.nvim_create_augroup('sops', { clear = true })

  --- Derive the buffer filetype from the filename extension.
  --- Falls back to stripping a leading `.enc.` segment when the
  --- direct extension is not in ft_map.
  ---@param fname string
  ---@return string|nil
  local function detect_filetype(fname)
    local ext = vim.fn.fnamemodify(fname, ':e')
    if M.config.ft_map[ext] then
      return M.config.ft_map[ext]
    end
    -- foo.enc.yml → try to extract the extension after .enc.
    local name = vim.fn.fnamemodify(fname, ':t')
    local base_ext = name:match('%.enc%.(%w+)$')
    if base_ext and M.config.ft_map[base_ext] then
      return M.config.ft_map[base_ext]
    end
    return nil
  end

  vim.api.nvim_create_autocmd('BufReadCmd', {
    group = augroup,
    pattern = M.config.patterns,
    callback = function(args)
      local fname = vim.fn.expand('<afile>')
      local buf = args.buf

      local ft = detect_filetype(fname)
      if ft then
        vim.bo[buf].filetype = ft
      end

      -- New file: nothing to decrypt
      if vim.fn.filereadable(fname) == 0 then
        return
      end

      -- Try SOPS decryption first; on failure read as plain text
      local output = vim.fn.system({ 'sops', '-d', fname })
      local ok = vim.v.shell_error == 0

      if ok then
        local lines = vim.split(output, '\n', { plain = true })
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      else
        local lines = vim.fn.readfile(fname)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      end

      vim.bo[buf].modified = false
    end,
  })

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    group = augroup,
    pattern = M.config.patterns,
    callback = function(args)
      local fname = vim.fn.expand('<afile>')
      local buf = args.buf

      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local content = table.concat(lines, '\n')

      -- Write plain content to a temp file, then encrypt in place to the real target.
      -- --filename-override makes sops resolve .sops.yaml relative to the target
      -- file (not the temp file) so it can find creation rules and key configuration.
      local tmpfile = vim.fn.tempname()
      vim.fn.writefile(vim.split(content, '\n'), tmpfile)

      -- Use vim.system (Neovim 0.10+) to capture stderr on failure
      local result = vim.system(
        { 'sops', '--encrypt', '--output', fname, '--filename-override', fname, tmpfile },
        { text = true }
      ):wait()

      vim.fn.delete(tmpfile)

      if result.code == 0 then
        vim.bo[buf].modified = false
        vim.api.nvim_echo({ { 'sops: encrypted and saved', 'Normal' } }, false, {})
      else
        local err = result.stderr or ''
        if err == '' then
          err = result.stdout or ''
        end
        vim.api.nvim_echo(
          { { 'sops encrypt failed!', 'ErrorMsg' }, { '\n' .. err, 'Normal' } },
          true,
          {}
        )
      end
    end,
  })
end

return M
