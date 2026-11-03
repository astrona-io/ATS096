# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** ordering across kinds

## Scenario

The repository `gitops/fleet` holds two folders. `infrastructure/podinfo-chart` has a `HelmRepository` and a `HelmRelease` for the podinfo chart, and `apps/consumer` has a ConfigMap `consumer-settings` that points at the Service `podinfo`. The ConfigMap must only be applied after the release is installed and healthy. The `GitRepository` `fleet` in `flux-system` is `Ready`, the namespace `podinfo-staging` exists, and no Flux `Kustomization` exists yet.

## Your task

Create two Flux `Kustomization` objects in the namespace `flux-system`, both from the source `fleet`, both with pruning on, both applying into `podinfo-staging`:

1. **`chart`** applies `./infrastructure/podinfo-chart` and is `Ready` only when the `HelmRelease` is healthy.
2. **`consumer`** applies `./apps/consumer` and waits for `chart`.

## Constraints

- Do not change the repository.
- Do not install the chart or the ConfigMap with `helm` or `kubectl`. Flux must do it.
- Do not give `consumer` a health check as a substitute for the dependency.

## Done when

- `flux get kustomizations` shows `chart` and `consumer` `Ready`.
- The `HelmRelease` `podinfo` in `podinfo-staging` is `Ready` and the ConfigMap `consumer-settings` exists there.
