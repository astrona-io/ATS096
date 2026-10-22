# Question

Solve this question on: `terminal`

**Time:** about 40 minutes · **Topic:** keeping the cluster equal to Git

## Scenario

An audit compared the cluster with Git and found three differences. In `podinfo-staging`, a ConfigMap `podinfo-legacy-settings` still runs, although its file was removed from Git weeks ago. Staging should answer with the message `staging v2`, which the Flux `Kustomization` `podinfo-staging` has asked for since yesterday, but it still answers `staging`. And in `podinfo-production`, someone scaled podinfo to 4 replicas by hand; the `HelmRelease` noticed and only warned.

## Your task

Make both environments follow Git again, and make sure they keep doing so:

1. **Staging:** the Flux `Kustomization` `podinfo-staging` prunes, the leftover ConfigMap `podinfo-legacy-settings` is gone, and podinfo in `podinfo-staging` answers with the message **`staging v2`**.
2. **Production:** the `HelmRelease` `podinfo` corrects drift, so a manual scale is put back to its **2** replicas at the next reconciliation.

## Constraints

- Fix the cause in Git where the cause is in Git: commit and push from your clone (the port-forward to Gitea must run). Do not only change the live object.
- Do not change the message in the Flux `Kustomization`; `staging v2` is right.
- Do not delete the staging Deployment, and do not delete and recreate the Flux objects.
- Do not ignore `/spec/replicas` in production.

## Done when

- `podinfo-staging` has `prune: true`, is `Ready`, and the ConfigMap `podinfo-legacy-settings` no longer exists.
- No file in Git carries the annotation `kustomize.toolkit.fluxcd.io/ssa`, and podinfo in staging answers `staging v2`.
- The production release has drift detection `enabled`, and a manual scale is reverted to 2 after `flux reconcile helmrelease podinfo -n podinfo-production`.
