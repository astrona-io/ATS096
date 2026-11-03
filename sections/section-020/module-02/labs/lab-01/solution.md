# Solution: Gate A Custom Resource With healthCheckExprs

Work the task yourself first. Running `astrona submit -c sections/section-020/module-02/labs/lab-01` after a step tells you which checks pass.

The grader checks that the Widget is in `healthChecks`, that an expression entry exists for the kind with `current` and `failed` reading `status.phase`, and that `widgets` is `Ready` while the Widget reports `Running`.

## Step 1: Create the Flux Kustomization

Save this as `kustomization-widgets.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: widgets
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 30s
  path: ./apps/widget
  prune: true
  wait: false
  timeout: 1m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  healthChecks:
    - apiVersion: demo.astrona.io/v1
      kind: Widget
      name: gauge
      namespace: podinfo-staging
  healthCheckExprs:
    - apiVersion: demo.astrona.io/v1
      kind: Widget
      inProgress: has(status.phase) && status.phase == 'Starting'
      failed: has(status.phase) && status.phase == 'Failed'
      current: has(status.phase) && status.phase == 'Running'
```

Apply it:

```sh
kubectl apply -f kustomization-widgets.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n podinfo-staging get widget gauge
```

The widget exists and `widgets` is not ready: no expression is true, because the widget has no status.

## Step 2: Play the controller

```sh
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p '{"status":{"phase":"Running"}}'
flux reconcile kustomization widgets
flux get kustomizations
```

`widgets` is now `Ready`.

## Step 3: Submit

```sh
astrona submit -c sections/section-020/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `wait: true` | The list `healthChecks` is ignored and the widget is called healthy without a status |
| Delete the health check | `widgets` is `Ready`, but a dependent stage no longer waits for the widget |
| Write the status in `widget.yaml` | A normal apply ignores `status` for a kind with a `status` subresource |

## Common mistakes

- Reading `status.phase` without `has()`, which is an error while the field is missing.
- A typo in the group of `apiVersion`, so the entry matches no object.
- Forgetting `namespace` in the `healthChecks` entry.
