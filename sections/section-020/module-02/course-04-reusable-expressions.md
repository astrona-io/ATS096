# Reusable Expressions

Most custom resources do not report one tidy field. They report conditions in a list, counters such as ready replicas, and the generation of the spec they have seen. This part shows the four expression patterns that cover most kinds, so that you can write a rule for an unknown kind from its status alone.

## Read a condition

A condition is an entry in the list `status.conditions` with a `type`, a `status` of `"True"`, `"False"` or `"Unknown"`, and usually a `reason`. CEL reads lists with `filter`, which keeps the entries that match, and `all` or `exists`, which test the entries. The expression below is true when the condition `Ready` is `"True"`:

```yaml
current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

`all` is true for an empty list. A kind without any condition then counts as healthy, the same quiet result as in the first part. Use `exists` when the condition must be present:

```yaml
current: status.conditions.exists(e, e.type == 'Ready' && e.status == 'True')
failed: status.conditions.exists(e, e.type == 'Ready' && e.status == 'False' && e.reason == 'Failed')
```

## Compare counters

Some kinds report how many parts are ready. The expression compares two numbers of the status, and `has()` protects the field that may be missing at the start:

```yaml
current: has(status.readyReplicas) && status.readyReplicas == spec.replicas
```

The expression reads the spec and the status of the same object, so it follows the desired count. If someone changes `spec.replicas`, the rule follows without an edit.

## Compare generations

A controller writes `status.observedGeneration` to say which version of the spec it has processed. Without a check on it, a health check can read the old status of an object whose spec just changed:

```yaml
current: has(status.observedGeneration) && status.observedGeneration == metadata.generation && status.phase == 'Running'
```

This expression is healthy only when the controller has seen the latest spec and reports `Running`. It is the safest pattern, because it never passes on a stale status.

## Combine the three expressions

A complete entry for a kind with conditions looks like this. It lists its kind once and covers the three states:

```yaml
healthCheckExprs:
  - apiVersion: demo.astrona.io/v1
    kind: Widget
    inProgress: has(status.phase) && status.phase == 'Starting'
    failed: has(status.phase) && status.phase == 'Failed'
    current: has(status.observedGeneration) && status.observedGeneration == metadata.generation && status.phase == 'Running'
```

<!-- astrona:playground:renew -->

Try the generation pattern on the widget of the playground. Save the entry above in place of the `healthCheckExprs` block of `kustomization-widgets.yaml`, apply it, and write a status that has no `observedGeneration`:

```sh
kubectl apply -f kustomization-widgets.yaml
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p '{"status":{"phase":"Running"}}'
flux reconcile kustomization widgets
```

The Flux `Kustomization` is not ready, because the status has no `observedGeneration`. Write the generation too, and it becomes `Ready`:

```sh
GENERATION=$(kubectl -n podinfo-staging get widget gauge -o jsonpath='{.metadata.generation}')
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p "{\"status\":{\"observedGeneration\":$GENERATION}}"
flux reconcile kustomization widgets
```

Writing the generation is what a controller does after it has processed the spec. You can now write a rule for conditions, counters and generations, and combine them in one entry.

## Common pitfalls

> [!WARNING]
> - **Using `all` on a list that may be empty.** An empty list passes. Use `exists` when the entry must be there.
> - **Comparing a string with a number.** `"True"` in a condition is a string, and `1` is an integer. A mismatch is false or an error.
> - **Ignoring `observedGeneration`.** A rule that reads an old status passes right after a spec change.
> - **One rule for many kinds.** Each entry names one kind. Write one entry per kind.
