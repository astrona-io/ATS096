# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** field ownership

## Scenario

The Flux `Kustomization` `podinfo-staging` in `flux-system` applies `./apps/podinfo/base` from the repository `gitops/fleet`. The Deployment `podinfo` in `podinfo-staging` has `replicas: 1` in Git, so Flux owns the field and sets it back at every reconciliation.

The team will run an autoscaler that sets the replica count from load. Until it exists, a person will play it with the field manager `autoscaler`.

## Your task

1. Change the repository so that Flux no longer owns `spec.replicas` of the Deployment `podinfo`, and let Flux apply the change.
2. Set the replicas to 4 with the field manager `autoscaler`.
3. Make sure the value 4 stays after a reconciliation.

## Constraints

- Do not suspend the Flux `Kustomization` and do not set `reconcile: disabled`.
- Do not use `ssa: IfNotPresent` or `ssa: Ignore`.
- Do not delete the Deployment.

## Done when

- `apps/podinfo/base/deployment.yaml` in Git does not set `replicas`.
- `kustomize-controller` does not own `spec.replicas` of the Deployment.
- The Deployment has 4 replicas and `podinfo-staging` is `Ready`.
