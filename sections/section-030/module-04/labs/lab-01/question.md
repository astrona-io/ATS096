# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** install options

## Scenario

The platform team keeps `HelmRelease` objects in `podinfo-staging`. The application must run in its own namespace `podinfo-app`, which does not exist yet. Helm's release records must stay in `podinfo-staging`, out of reach of the application team, and only the three newest revisions are kept. The `HelmRepository` `podinfo` in `flux-system` is `Ready`.

## Your task

Create a `HelmRelease` named `podinfo` in the namespace `podinfo-staging` with an `interval` of `10m`, installing the chart `podinfo` at version `6.15.0` from the `HelmRepository` `podinfo` in `flux-system`.

1. The Helm release is named `podinfo`.
2. The objects of the chart are installed into the namespace `podinfo-app`, which Flux creates.
3. Helm's storage Secrets are in `podinfo-staging`.
4. Helm keeps at most three revisions.

## Constraints

- Do not create the namespace `podinfo-app` yourself.
- Do not put the `HelmRelease` in `podinfo-app`.
- Do not use a version range.

## Done when

- `flux get helmreleases -n podinfo-staging` shows `podinfo` `Ready`.
- The Deployment `podinfo` runs in `podinfo-app`.
- The Helm Secrets of the release are in `podinfo-staging` and none are in `podinfo-app`.
