# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Helm delivery and remediation

## Scenario

The team installs podinfo from its Helm chart into staging and production, and keeps each environment's values in a ConfigMap so they can be reviewed apart from the release. Last time an upgrade with a wrong image tag left production failed for an hour, because nobody rolled it back. The `HelmRepository` `podinfo` in `flux-system` already points at `https://stefanprodan.github.io/podinfo`, and the namespaces `podinfo-staging` and `podinfo-production` exist.

## Your task

1. In each of the namespaces `podinfo-staging` and `podinfo-production`, create a ConfigMap **`podinfo-values`** with the chart values under the key `values.yaml`:
   - staging: `replicaCount: 1`, `ui.message: staging`
   - production: `replicaCount: 2`, `ui.message: production`
2. In each namespace, create a `HelmRelease` **`podinfo`** with the release name `podinfo` that installs the chart `podinfo` at version **`6.15.0`** from the `HelmRepository` `podinfo`, with its values from that namespace's ConfigMap `podinfo-values`.
3. Make production roll back a failed upgrade on its own: at least **1** upgrade retry with the strategy `rollback`. A `timeout` of `1m` makes the next step quicker.
4. Test it: add `image.tag: 0.0.0-missing` to the production ConfigMap, reconcile, and let helm-controller fail and roll back. Then remove the bad tag again so production ends on a working release.

## Constraints

- Keep the values in the ConfigMaps; do not put them inline in the `HelmRelease`.
- Do not use the `helm` command, and do not delete Helm's storage Secrets. The grader reads them to see the rollback.

## Done when

- `flux get helmreleases -A` shows both releases `Ready`.
- podinfo answers `staging` with 1 replica in `podinfo-staging`, and `production` with 2 replicas in `podinfo-production`.
- Helm's storage in `podinfo-production` holds at least one `failed` revision, and the deployed release runs the image tag `6.15.0`.
