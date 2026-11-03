# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** securing what Flux applies

## Scenario

The Flux `Kustomization` `podinfo-secure` in `flux-system` applies the folder `apps/podinfo/base` of the repository `gitops/fleet` into the namespace `podinfo-staging`. The folder contains a Secret named `podinfo-credentials`, stored as `secret.sops.yaml` and encrypted with SOPS and an age key. The age private key is already in the cluster, as the Secret `sops-age` in `flux-system`, under the key `age.agekey`. The Deployment `podinfo` reads its message from the Secret, so it cannot start. `podinfo-secure` is not `Ready`.

## Your task

Make Flux decrypt the Secret and apply it:

1. Find out why `podinfo-secure` is not `Ready`. Read its status message and its events.
2. Change the Flux `Kustomization` `podinfo-secure` so that kustomize-controller decrypts files with SOPS, using the key in the Secret `sops-age`.
3. Let Flux apply the change.

## Constraints

- Keep the path `./apps/podinfo/base`, the source `fleet` and `prune: true`.
- Keep `secret.sops.yaml` encrypted in Git. Do not commit the plain text value.
- Do not create the Secret `podinfo-credentials` with `kubectl`. Flux must apply it.
- Do not suspend the Flux `Kustomization`.

## Done when

- `flux get kustomizations` shows `podinfo-secure` `Ready`.
- The Secret `podinfo-credentials` in `podinfo-staging` holds the message `sealed-by-sops`, and the file in Git is still encrypted.
- A request from the `tester` pod to `http://podinfo.podinfo-staging:9898` answers with the message `sealed-by-sops`.
