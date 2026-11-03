# Prerequisites

Before starting this lab you should be able to:

- Read a Kustomize file `kustomization.yaml` with `resources` and `replacements`.
- Preview a build with `kubectl kustomize` and `flux build kustomization`.
- Read the status of a Flux `Kustomization` with `flux get kustomizations`, `flux events` and `kubectl describe`.
- Clone, edit, commit and push a Git repository.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- The namespaces `podinfo-staging` and `podinfo-production`.
- In the repository, the folders `apps/podinfo/base` and `apps/podinfo/overlay`. The overlay uses a replacement.
- The Flux `Kustomization` `podinfo-staging`, which is not `Ready`.

## Working rules

- Everything is graded on the **final state** of the cluster and the repository, so check `flux get` at the end and leave the fix in place.
- The state has more than one fault. Fix one, check again, and read the new message before you fix the next.
- Do not remove the replacement and do not use `postBuild` or `patches` to set the message.
