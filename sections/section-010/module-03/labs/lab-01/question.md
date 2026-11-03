# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** building and shaping what Flux applies

## Scenario

The Flux `Kustomization` `podinfo-staging` in `flux-system` should deploy `podinfo` into the namespace `podinfo-staging` from the repository `gitops/fleet`. The overlay `apps/podinfo/overlay` keeps the message in the ConfigMap `podinfo-settings` and copies it into the environment variable `PODINFO_UI_MESSAGE` of the Deployment with a replacement. The Flux `Kustomization` is not `Ready` and nothing is deployed.

## Your task

Find out why `podinfo-staging` fails and repair it, so that the overlay builds and the Deployment `podinfo` answers with the message from the ConfigMap, **`from-replacement`**.

There is more than one fault. One is in the cluster and one is in Git. Read the status and the events of the Flux `Kustomization`, and preview the build, to find them.

## Constraints

- Keep the Flux `Kustomization` `podinfo-staging` with `prune: true`, the source `fleet` and the target namespace `podinfo-staging`. Do not delete and re-create it under another name.
- Keep the replacement in the overlay. Do not set the message with `postBuild`, with `patches` or with `kubectl`.
- Do not suspend the Flux `Kustomization`. Flux must apply the Deployment.

## Done when

- `flux get kustomizations` shows `podinfo-staging` `Ready`.
- The Deployment `podinfo` in `podinfo-staging` has 1 ready replica, and its `PODINFO_UI_MESSAGE` was set by the replacement.
- A request from the `tester` pod to `http://podinfo.podinfo-staging:9898` answers with the message `from-replacement`.
