# Writing healthCheckExprs

A custom resource with its own status fields needs its own rule. This part adds the field `healthCheckExprs` to the Flux `Kustomization` of the previous part, so that the widget counts as healthy only when its `status.phase` is `Running`. You write the three expressions, learn the order in which kustomize-controller tries them, and see the Flux `Kustomization` wait for a widget that is still starting.

## The three expressions

`healthCheckExprs` is a list. Each entry describes one kind and holds up to three expressions in the Common Expression Language (CEL), a small language for checks that return true or false. The expression reads the fields of the object directly, for example `status.phase`.

| Field | Meaning when the expression is true |
| --- | --- |
| `inProgress` | The object is still working towards its goal |
| `failed` | The object has failed and will not recover by waiting |
| `current` | The object is healthy |

kustomize-controller tries them in the order `inProgress`, `failed`, `current`. The first expression that is true decides. An entry names its kind with `apiVersion` and `kind`, and only the group of the `apiVersion` is compared. At least `current` is required.

An expression that is true for `failed` makes the health check stop at once with the reason `HealthCheckFailed`. Without a `failed` expression, a broken widget is waited for until the `timeout` ends.

## Name the object and the rule

The expressions say how to judge a kind. The field `healthChecks` says which objects to judge. Add both to the Flux `Kustomization` and turn `wait` off, because with `wait: true` the list `healthChecks` is ignored.

Save this as `kustomization-widgets.yaml`:

<!-- astrona:playground:renew -->

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

The function `has(status.phase)` is true when the field exists. It protects the other comparisons, because reading a field that does not exist is an error in CEL.

Apply it:

```sh
kubectl apply -f kustomization-widgets.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n flux-system describe kustomization widgets
```

`widgets` is not ready. The widget has no `status.phase`, so none of the three expressions is true, and the health check keeps waiting until the `timeout` of one minute ends. The message names the Widget `gauge` as not ready. The apply itself worked: the object exists, and only the health check holds the `Ready` condition back.

## Why the entry needs both lists

If the entry in `healthCheckExprs` exists but the object is in neither `healthChecks` nor covered by `wait: true`, kustomize-controller never checks it. The expressions only change how a checked object is judged. If the object is in `healthChecks` but no expression matches its kind, the default kstatus rule from the previous part applies.

You can now write a rule for a kind and tell Flux which objects to apply it to. The open question is how to prove the rule works before a real controller exists, which the next part answers by writing the status yourself.

## Common pitfalls

> [!WARNING]
> - **Leaving `wait: true` on.** The list `healthChecks` is then ignored, and the objects are judged by the default rule.
> - **Reading a field without `has()`.** An expression that reads a missing field is an error, and the check cannot decide.
> - **A wrong group in `apiVersion`.** The group is what is compared. A typo means the entry matches nothing and the default rule applies silently.
> - **No `failed` expression.** A widget that failed for good is waited for until `timeout` ends, and the report says only that it is not ready.
