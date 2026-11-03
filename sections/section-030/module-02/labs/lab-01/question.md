# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** charts from Git

## Scenario

The repository `gitops/fleet` holds a small chart in `charts/hello`. It writes one ConfigMap named after the release, with the key `message`. The chart has a `values.yaml` with the message `default` and a `values-staging.yaml` with the message `staging`. The `GitRepository` `fleet` in `flux-system` is `Ready`. No `HelmRelease` exists yet.

Developers edit the templates of this chart often and do not always change `version` in `Chart.yaml`.

## Your task

Create a `HelmRelease` named `hello` in the namespace `podinfo-staging` that installs the chart `./charts/hello` from the source `fleet`, with an `interval` of `10m`.

1. The chart comes from the `GitRepository` `fleet` in the namespace `flux-system`.
2. A change to the chart must reach the cluster even when `version` does not change.
3. The release uses `values.yaml` and then `values-staging.yaml`.

## Constraints

- Do not change the repository.
- Do not set the message with `spec.values`.
- Do not create a `HelmRepository`.

## Done when

- `flux get helmreleases -n podinfo-staging` shows `hello` `Ready`.
- The ConfigMap `hello-config` in `podinfo-staging` holds the message `staging`.
- The release carries the settings described above.
