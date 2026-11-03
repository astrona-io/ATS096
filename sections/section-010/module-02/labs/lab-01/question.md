# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** building and shaping what Flux applies

## Scenario

The Flux `Kustomization` `podinfo-staging` in `flux-system` applies the overlay `apps/podinfo/overlays/staging` of the repository `gitops/fleet` into the namespace `podinfo-staging`. The overlay lists a plain ConfigMap file, `configmap.yaml`, that holds the message `staging`. The Deployment `podinfo` reads that ConfigMap with `envFrom`. When the team changes the message in the ConfigMap, Flux updates the ConfigMap, but the pod keeps running with the old message until someone restarts it.

## Your task

Change the staging overlay in Git so that a new message rolls the pods by itself, and set the message to **`rolled-out`**:

1. In `apps/podinfo/overlays/staging/kustomization.yaml`, replace the plain ConfigMap file with a `configMapGenerator` that creates the ConfigMap `podinfo-config` with the key `PODINFO_UI_MESSAGE` and the value `rolled-out`.
2. Commit and push the change to the branch `main`.
3. Let Flux apply it.

## Constraints

- Keep the Flux `Kustomization` `podinfo-staging` as it is: same path, same source, `prune: true`.
- Do not change the base, and do not restart the Deployment with `kubectl`.
- Do not edit the ConfigMap or the Deployment in the cluster. Flux must apply the change from Git.

## Done when

- `flux get kustomizations` shows `podinfo-staging` `Ready`.
- The Deployment `podinfo` in `podinfo-staging` reads a ConfigMap named `podinfo-config-<hash>`, Flux applied it, and no other ConfigMap whose name starts with `podinfo-config` is left in the namespace.
- A request from the `tester` pod to `http://podinfo.podinfo-staging:9898` answers with the message `rolled-out`.
