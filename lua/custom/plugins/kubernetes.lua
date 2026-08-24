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
--     Trigger in a yaml buffer + <C-y> to expand: kpod, kdeploy, kservice,
--     knodeport, kconfigmap, ksecret, kingress, kstatefulset, kdaemonset,
--     kjob, kcronjob, kpvc, ksa, khpa, knetpol, knamespace.
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

    -- Deployment boilerplate
    ls.s('kdeploy', fmta(
      'apiVersion: apps/v1\n'
      .. 'kind: Deployment\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. '  labels:\n'
      .. '    app: <>\n'
      .. 'spec:\n'
      .. '  replicas: <>\n'
      .. '  selector:\n'
      .. '    matchLabels:\n'
      .. '      app: <>\n'
      .. '  template:\n'
      .. '    metadata:\n'
      .. '      labels:\n'
      .. '        app: <>\n'
      .. '    spec:\n'
      .. '      containers:\n'
      .. '      - name: <>\n'
      .. '        image: <>\n'
      .. '        ports:\n'
      .. '        - containerPort: <>\n'
      .. '        resources:\n'
      .. '          requests:\n'
      .. '            cpu: <>\n'
      .. '            memory: <>\n'
      .. '          limits:\n'
      .. '            cpu: <>\n'
      .. '            memory: <>',
      {
        ls.i(1, 'deployment-name'),
        ls.i(2, 'app-name'),
        ls.i(3, '3'),
        ls.f(function(args) return args[1][1] end, { 2 }),
        ls.f(function(args) return args[1][1] end, { 2 }),
        ls.i(4, 'container-name'),
        ls.i(5, 'nginx:latest'),
        ls.i(6, '80'),
        ls.i(7, '100m'),
        ls.i(8, '128Mi'),
        ls.i(9, '250m'),
        ls.i(10, '256Mi'),
      }
    )),

    -- Service (ClusterIP) boilerplate
    ls.s('kservice', fmta(
      'apiVersion: v1\n'
      .. 'kind: Service\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. '  labels:\n'
      .. '    app: <>\n'
      .. 'spec:\n'
      .. '  type: ClusterIP\n'
      .. '  selector:\n'
      .. '    app: <>\n'
      .. '  ports:\n'
      .. '  - name: http\n'
      .. '    port: <>\n'
      .. '    targetPort: <>\n'
      .. '    protocol: TCP',
      {
        ls.i(1, 'service-name'),
        ls.i(2, 'app-name'),
        ls.i(3, 'app-name'),
        ls.i(4, '80'),
        ls.i(5, '8080'),
      }
    )),

    -- Service (NodePort) boilerplate
    ls.s('knodeport', fmta(
      'apiVersion: v1\n'
      .. 'kind: Service\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. '  labels:\n'
      .. '    app: <>\n'
      .. 'spec:\n'
      .. '  type: NodePort\n'
      .. '  selector:\n'
      .. '    app: <>\n'
      .. '  ports:\n'
      .. '  - name: http\n'
      .. '    port: <>\n'
      .. '    targetPort: <>\n'
      .. '    nodePort: <>\n'
      .. '    protocol: TCP',
      {
        ls.i(1, 'service-name'),
        ls.i(2, 'app-name'),
        ls.i(3, 'app-name'),
        ls.i(4, '80'),
        ls.i(5, '8080'),
        ls.i(6, '30080'),
      }
    )),

    -- ConfigMap boilerplate
    ls.s('kconfigmap', fmta(
      'apiVersion: v1\n'
      .. 'kind: ConfigMap\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'data:\n'
      .. '  <>: |\n'
      .. '    <>',
      {
        ls.i(1, 'configmap-name'),
        ls.i(2, 'key.conf'),
        ls.i(3, '# configuration goes here'),
      }
    )),

    -- Secret boilerplate (base64 values)
    ls.s('ksecret', fmta(
      'apiVersion: v1\n'
      .. 'kind: Secret\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'type: Opaque\n'
      .. 'data:\n'
      .. '  <>: <>',
      {
        ls.i(1, 'secret-name'),
        ls.i(2, 'password'),
        ls.i(3, 'c2VjcmV0'),
      }
    )),

    -- Ingress boilerplate
    ls.s('kingress', fmta(
      'apiVersion: networking.k8s.io/v1\n'
      .. 'kind: Ingress\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  ingressClassName: <>\n'
      .. '  rules:\n'
      .. '  - host: <>\n'
      .. '    http:\n'
      .. '      paths:\n'
      .. '      - path: /\n'
      .. '        pathType: Prefix\n'
      .. '        backend:\n'
      .. '          service:\n'
      .. '            name: <>\n'
      .. '            port:\n'
      .. '              number: <>',
      {
        ls.i(1, 'ingress-name'),
        ls.i(2, 'nginx'),
        ls.i(3, 'example.com'),
        ls.i(4, 'service-name'),
        ls.i(5, '80'),
      }
    )),

    -- StatefulSet boilerplate
    ls.s('kstatefulset', fmta(
      'apiVersion: apps/v1\n'
      .. 'kind: StatefulSet\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  serviceName: <>\n'
      .. '  replicas: <>\n'
      .. '  selector:\n'
      .. '    matchLabels:\n'
      .. '      app: <>\n'
      .. '  template:\n'
      .. '    metadata:\n'
      .. '      labels:\n'
      .. '        app: <>\n'
      .. '    spec:\n'
      .. '      containers:\n'
      .. '      - name: <>\n'
      .. '        image: <>\n'
      .. '        ports:\n'
      .. '        - containerPort: <>\n'
      .. '          name: http\n'
      .. '        volumeMounts:\n'
      .. '        - name: data\n'
      .. '          mountPath: /data\n'
      .. '  volumeClaimTemplates:\n'
      .. '  - metadata:\n'
      .. '      name: data\n'
      .. '    spec:\n'
      .. '      accessModes: [ "ReadWriteOnce" ]\n'
      .. '      storageClassName: <>\n'
      .. '      resources:\n'
      .. '        requests:\n'
      .. '          storage: <>',
      {
        ls.i(1, 'statefulset-name'),
        ls.i(2, 'headless-service-name'),
        ls.i(3, '3'),
        ls.i(4, 'app-name'),
        ls.f(function(args) return args[1][1] end, { 4 }),
        ls.i(5, 'container-name'),
        ls.i(6, 'nginx:latest'),
        ls.i(7, '80'),
        ls.i(8, 'standard'),
        ls.i(9, '1Gi'),
      }
    )),

    -- DaemonSet boilerplate
    ls.s('kdaemonset', fmta(
      'apiVersion: apps/v1\n'
      .. 'kind: DaemonSet\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. '  labels:\n'
      .. '    app: <>\n'
      .. 'spec:\n'
      .. '  selector:\n'
      .. '    matchLabels:\n'
      .. '      app: <>\n'
      .. '  template:\n'
      .. '    metadata:\n'
      .. '      labels:\n'
      .. '        app: <>\n'
      .. '    spec:\n'
      .. '      containers:\n'
      .. '      - name: <>\n'
      .. '        image: <>\n'
      .. '        resources:\n'
      .. '          requests:\n'
      .. '            cpu: 100m\n'
      .. '            memory: 128Mi\n'
      .. '          limits:\n'
      .. '            cpu: 250m\n'
      .. '            memory: 256Mi',
      {
        ls.i(1, 'daemonset-name'),
        ls.i(2, 'app-name'),
        ls.f(function(args) return args[1][1] end, { 2 }),
        ls.f(function(args) return args[1][1] end, { 2 }),
        ls.i(3, 'container-name'),
        ls.i(4, 'nginx:latest'),
      }
    )),

    -- Job boilerplate
    ls.s('kjob', fmta(
      'apiVersion: batch/v1\n'
      .. 'kind: Job\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  template:\n'
      .. '    metadata:\n'
      .. '      labels:\n'
      .. '        app: <>\n'
      .. '    spec:\n'
      .. '      restartPolicy: Never\n'
      .. '      containers:\n'
      .. '      - name: <>\n'
      .. '        image: <>\n'
      .. '        command: ["<>"]\n'
      .. '        args:\n'
      .. '        - <>',
      {
        ls.i(1, 'job-name'),
        ls.i(2, 'app-name'),
        ls.i(3, 'container-name'),
        ls.i(4, 'busybox'),
        ls.i(5, 'echo'),
        ls.i(6, 'hello'),
      }
    )),

    -- CronJob boilerplate
    ls.s('kcronjob', fmta(
      'apiVersion: batch/v1\n'
      .. 'kind: CronJob\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  schedule: "<>"\n'
      .. '  concurrencyPolicy: Forbid\n'
      .. '  successfulJobsHistoryLimit: 3\n'
      .. '  failedJobsHistoryLimit: 3\n'
      .. '  jobTemplate:\n'
      .. '    spec:\n'
      .. '      template:\n'
      .. '        spec:\n'
      .. '          restartPolicy: Never\n'
      .. '          containers:\n'
      .. '          - name: <>\n'
      .. '            image: <>\n'
      .. '            command: ["<>"]',
      {
        ls.i(1, 'cronjob-name'),
        ls.i(2, '*/5 * * * *'),
        ls.i(3, 'container-name'),
        ls.i(4, 'busybox'),
        ls.i(5, 'echo'),
      }
    )),

    -- PersistentVolumeClaim boilerplate
    ls.s('kpvc', fmta(
      'apiVersion: v1\n'
      .. 'kind: PersistentVolumeClaim\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  accessModes:\n'
      .. '  - ReadWriteOnce\n'
      .. '  storageClassName: <>\n'
      .. '  resources:\n'
      .. '    requests:\n'
      .. '      storage: <>',
      {
        ls.i(1, 'pvc-name'),
        ls.i(2, 'standard'),
        ls.i(3, '1Gi'),
      }
    )),

    -- ServiceAccount boilerplate
    ls.s('ksa', fmta(
      'apiVersion: v1\n'
      .. 'kind: ServiceAccount\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default',
      {
        ls.i(1, 'service-account-name'),
      }
    )),

    -- HorizontalPodAutoscaler boilerplate
    ls.s('khpa', fmta(
      'apiVersion: autoscaling/v2\n'
      .. 'kind: HorizontalPodAutoscaler\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  scaleTargetRef:\n'
      .. '    apiVersion: apps/v1\n'
      .. '    kind: Deployment\n'
      .. '    name: <>\n'
      .. '  minReplicas: <>\n'
      .. '  maxReplicas: <>\n'
      .. '  metrics:\n'
      .. '  - type: Resource\n'
      .. '    resource:\n'
      .. '      name: cpu\n'
      .. '      target:\n'
      .. '        type: Utilization\n'
      .. '        averageUtilization: <>',
      {
        ls.i(1, 'hpa-name'),
        ls.i(2, 'deployment-name'),
        ls.i(3, '2'),
        ls.i(4, '10'),
        ls.i(5, '80'),
      }
    )),

    -- NetworkPolicy boilerplate (default-deny ingress)
    ls.s('knetpol', fmta(
      'apiVersion: networking.k8s.io/v1\n'
      .. 'kind: NetworkPolicy\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  namespace: default\n'
      .. 'spec:\n'
      .. '  podSelector: {}\n'
      .. '  policyTypes:\n'
      .. '  - Ingress\n'
      .. '  - Egress\n'
      .. '  ingress: []\n'
      .. '  egress: []',
      {
        ls.i(1, 'default-deny-all'),
      }
    )),

    -- Namespace boilerplate
    ls.s('knamespace', fmta(
      'apiVersion: v1\n'
      .. 'kind: Namespace\n'
      .. 'metadata:\n'
      .. '  name: <>\n'
      .. '  labels:\n'
      .. '    name: <>',
      {
        ls.i(1, 'namespace-name'),
        ls.f(function(args) return args[1][1] end, { 1 }),
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
