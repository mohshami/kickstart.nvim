-- =============================================================================
-- andrewstuart/vim-kubernetes + blink.cmp custom source for Kubernetes manifests
-- Pure Vimscript plugin + kubectl-based completion (no nodejs)
-- Repo: https://github.com/andrewstuart/vim-kubernetes
-- Completion source: ./kubernetes/source.lua
-- =============================================================================

-- 1. Install the plugin (pure Vimscript; provides ftdetect, :KubeApply,
--    :KubeDelete, :KubeCreate, :KubeDecodeSecret/:KubeEncodeSecret).
vim.pack.add { 'https://github.com/andrewstuart/vim-kubernetes' }

-- 2. Plugin notes
--   The plugin auto-sets `filetype=yaml` on any buffer whose first line starts
--   with `kind:` or `apiVersion:` (see ftdetect/kubeconf.vim in the repo).
--   Our blink.cmp source additionally scans the first 200 lines to confirm the
--   buffer is a k8s manifest before activating completion.

-- 3. Register the blink.cmp source. `module` is a string so blink.cmp can
--    lazy-require it; the source module lives in ./kubernetes/source.lua.
require('blink.cmp').add_source_provider('k8s', {
  module = 'custom.plugins.kubernetes.source',
})

-- 3b. LuaSnip boilerplate snippets (LuaSnip is already loaded by init.lua
--     SECTION 8 and exposed to blink.cmp via `snippets = { preset = 'luasnip' }`).
--     Trigger `kpod` + <C-y> in a yaml buffer to expand.
--     Uses `fmta` (fmt with <> delimiters) which handles newlines cleanly
--     across insert boundaries — unlike plain `t()` nodes.
do
  local ls = require('luasnip')
  local fmta = require('luasnip.extras.fmt').fmta

  ls.add_snippets('yaml', {
    -- Pod boilerplate
    ls.s('kpod', fmta(
      'apiVersion: v1\n'
      .. 'kind: Pod\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. '  labels:\n'
      .. '    app: <>\n'
      .. 'spec:\n'
      .. '  containers:\n'
      .. '  - name: <>\n'
      .. '    image: <>\n'
      .. '    ports:\n'
      .. '    - containerPort: <>\n'
      .. '      protocol: TCP',
      {
        ls.i(1, 'pod-name'),
        ls.i(2, 'app-name'),
        ls.i(3, 'container-name'),
        ls.i(4, 'nginx:latest'),
        ls.i(5, '80'),
      }
    )),
  })
end

-- 4. Keymaps: cycle kubectl context / namespace
local source = require('custom.plugins.kubernetes.source')

local function kubectl_run(args)
  local out = vim.fn.systemlist({ 'kubectl', unpack(args) })
  if vim.v.shell_error ~= 0 then return nil end
  return out
end

local function cycle_context()
  if vim.fn.executable('kubectl') == 0 then
    vim.notify('kubectl not found in $PATH', vim.log.levels.WARN)
    return
  end
  local contexts = kubectl_run({ 'config', 'get-contexts', '-o', 'name' })
  if not contexts or #contexts == 0 then
    vim.notify('No kubectl contexts found', vim.log.levels.WARN)
    return
  end
  local current = (kubectl_run({ 'config', 'current-context' }) or { '' })[1]
  local idx = 1
  for i, c in ipairs(contexts) do
    if c == current then
      idx = (i % #contexts) + 1
      break
    end
  end
  vim.fn.system({ 'kubectl', 'config', 'use-context', contexts[idx] })
  vim.notify('kubectl context → ' .. contexts[idx], vim.log.levels.INFO)
  -- Invalidate cache so the next completion shows the new cluster's namespaces.
  source.invalidate_cache()
end

local function cycle_namespace()
  if vim.fn.executable('kubectl') == 0 then
    vim.notify('kubectl not found in $PATH', vim.log.levels.WARN)
    return
  end
  local ns_out = kubectl_run({ 'get', 'ns', '-o', 'name' })
  if not ns_out or #ns_out == 0 then
    vim.notify('No namespaces visible to current context', vim.log.levels.WARN)
    return
  end
  local namespaces = vim.tbl_map(function(s)
    return (s:gsub('^namespace/', ''))
  end, ns_out)
  local current = (kubectl_run({
    'config', 'view', '--minify', '-o', 'jsonpath={..namespace}',
  }) or { 'default' })[1]
  if current == '' then current = 'default' end

  local idx = 1
  for i, ns in ipairs(namespaces) do
    if ns == current then
      idx = (i % #namespaces) + 1
      break
    end
  end
  vim.fn.system({ 'kubectl', 'config', 'set-context', '--current', '--namespace', namespaces[idx] })
  vim.notify('kubectl namespace → ' .. namespaces[idx], vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>kcc', cycle_context, { desc = '[K]8s cycle [C]ontext' })
vim.keymap.set('n', '<leader>kcn', cycle_namespace, { desc = '[K]8s cycle [N]amespace' })
