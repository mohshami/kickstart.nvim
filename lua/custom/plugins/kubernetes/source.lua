-- =============================================================================
-- blink.cmp custom source: Kubernetes contexts, namespaces, and resource kinds.
-- Pure-Lua source, no nodejs. Shells out to `kubectl` for live data.
-- Module path:  custom.plugins.kubernetes.source
-- Registered from: lua/custom/plugins/kubernetes.lua
-- =============================================================================

local M = {}

local has_kubectl = vim.fn.executable('kubectl') == 1

local K8S_KINDS = {
  -- Full names
  'Pod', 'Service', 'Deployment', 'StatefulSet', 'DaemonSet',
  'Job', 'CronJob', 'ConfigMap', 'Secret', 'ServiceAccount',
  'Ingress', 'NetworkPolicy', 'PersistentVolume', 'PersistentVolumeClaim',
  'Namespace', 'Node', 'Event', 'Endpoint', 'ReplicaSet',
  'HorizontalPodAutoscaler', 'PodDisruptionBudget',
  'Role', 'RoleBinding', 'ClusterRole', 'ClusterRoleBinding',
  'CustomResourceDefinition', 'StorageClass', 'VolumeAttachment',
  -- Common kubectl short names
  'po', 'svc', 'deploy', 'sts', 'ds', 'cj', 'cm', 'sa',
  'ing', 'netpol', 'pv', 'pvc', 'no', 'ep', 'rs', 'hpa',
  'pdb', 'crd', 'sc',
}

---Detect whether the buffer is a Kubernetes manifest by scanning the first
---200 lines for `apiVersion:` and `kind:` keys (the defining fields).
---@param bufnr integer
---@return boolean
local function is_k8s_manifest(bufnr)
  bufnr = bufnr or 0
  local ok, lines = pcall(vim.api.nvim_buf_get_lines, bufnr, 0, 200, false)
  if not ok then return false end
  local has_api, has_kind = false, false
  for _, line in ipairs(lines) do
    if not has_api then has_api = line:match('^%s*apiVersion:%s') ~= nil end
    if not has_kind then has_kind = line:match('^%s*kind:%s') ~= nil end
    if has_api and has_kind then return true end
  end
  return false
end

-- Lightweight TTL cache so we don't shell out to `kubectl` on every keystroke.
local cache = { ts = 0, data = { contexts = {}, namespaces = {} } }
local CACHE_TTL = 30 -- seconds

local function refresh_cache()
  if not has_kubectl then return end
  local data = { contexts = {}, namespaces = {} }
  local ctx_out = vim.fn.systemlist({ 'kubectl', 'config', 'get-contexts', '-o', 'name' })
  if vim.v.shell_error == 0 then
    data.contexts = ctx_out
  end
  local ns_out = vim.fn.systemlist({ 'kubectl', 'get', 'ns', '-o', 'name' })
  if vim.v.shell_error == 0 then
    data.namespaces = vim.tbl_map(function(s)
      return (s:gsub('^namespace/', ''))
    end, ns_out)
  end
  cache.ts = os.time()
  cache.data = data
end

local function get_data()
  if not has_kubectl then return cache.data end
  if os.time() - cache.ts > CACHE_TTL then refresh_cache() end
  return cache.data
end

---Public hook for the keymap cycle functions to invalidate the cache after
---the user switches context/namespace so completion picks up the new state.
function M.invalidate_cache()
  cache.ts = 0
end

function M.new()
  return setmetatable({}, { __index = M })
end

---Gate the source: only activate in buffers that look like k8s manifests.
function M:enabled()
  return has_kubectl and is_k8s_manifest()
end

---blink.cmp 1.x calls :complete() with (ctx, callback).
function M:complete(_ctx, callback)
  local items = {}
  local Kind = require('blink.cmp.types').CompletionItemKind
  local data = get_data()

  for _, c in ipairs(data.contexts) do
    table.insert(items, {
      label = c,
      kind = Kind.Reference,
      detail = 'kubectl context',
      insertText = c,
    })
  end
  for _, ns in ipairs(data.namespaces) do
    table.insert(items, {
      label = ns,
      kind = Kind.Module,
      detail = 'namespace',
      insertText = ns,
    })
  end
  for _, k in ipairs(K8S_KINDS) do
    table.insert(items, {
      label = k,
      kind = Kind.Class,
      detail = 'k8s Kind',
      insertText = k,
    })
  end

  callback(items)
end

return M
