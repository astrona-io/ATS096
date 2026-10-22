# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** building and shaping what Flux applies

## Scenario

The repository `gitops/fleet` holds one base for the `podinfo` application in `apps/podinfo/base`. The team wants it in two environments, staging and production, without copying the folder. The `GitRepository` `fleet` in `flux-system` is already `Ready`, and the namespaces `podinfo-staging` and `podinfo-production` exist. Nothing deploys `podinfo` yet.

## Your task

Create two Flux `Kustomization` objects in the namespace `flux-system` that both build `./apps/podinfo/base` from the source `fleet`:

1. **`podinfo-staging`** applies into the namespace `podinfo-staging`. The Deployment `podinfo` runs **1** replica, carries the label `environment: staging`, and answers with the message **`staging`**.
2. **`podinfo-production`** applies into the namespace `podinfo-production`. The Deployment `podinfo` runs **2** replicas, carries the label `environment: production`, and answers with the message **`production`**.

Both must have pruning on and must be `Ready`.

## Constraints

- Do not change the repository. Both environments use the base as it is.
- Set the production replica count with a patch in the Flux `Kustomization`, and the label and the message with post-build variable substitution.
- Do not apply the application's manifests yourself with `kubectl`. Flux must apply them.

## Done when

- `flux get kustomizations` shows both objects `Ready`.
- A request from the `tester` pod to `http://podinfo.podinfo-staging:9898` answers with the message `staging`, and one to `http://podinfo.podinfo-production:9898` answers with `production`.
- The staging Deployment has 1 ready replica and the production Deployment has 2.
