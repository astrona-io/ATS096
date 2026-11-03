# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** health rules for custom resources

## Scenario

The platform team runs a `Widget` controller. The kind `Widget` (`demo.astrona.io/v1`) is already defined in the cluster, and the repository `gitops/fleet` holds one object in `apps/widget`: the Widget `gauge`. The `GitRepository` `fleet` in `flux-system` is `Ready`. A stage that depends on the widget must not go ahead until the widget really runs, but the Widget reports its state only in `status.phase`: `Starting`, `Running` or `Failed`. No Flux `Kustomization` exists yet, and no widget controller runs in this cluster.

## Your task

Create a Flux `Kustomization` named `widgets` in the namespace `flux-system` that applies `./apps/widget` from the source `fleet` into the namespace `podinfo-staging`, with pruning on and a `timeout` of `1m`.

It must be `Ready` only when the widget is healthy:

1. The Widget `gauge` is named in `healthChecks`.
2. A `healthCheckExprs` entry for the kind `Widget` of `demo.astrona.io/v1` has `inProgress` for `Starting`, `failed` for `Failed` and `current` for `Running`, all reading `status.phase`.
3. After Flux applied the widget, play the controller: write the phase `Running` into the status of the widget.

## Constraints

- Do not change the repository.
- Do not set `wait: true`, which would ignore `healthChecks`.
- Do not make the object `Ready` by removing the health check.

## Done when

- `flux get kustomizations` shows `widgets` `Ready`.
- The Widget `gauge` in `podinfo-staging` reports `status.phase` `Running`.
- The Flux `Kustomization` carries the expressions described above.
