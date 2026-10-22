# Prerequisites

Before starting this capstone you should be able to:

- Read a Flux `Kustomization` with `prune` and its `.status.inventory`.
- Explain the `kustomize.toolkit.fluxcd.io/ssa` annotation values.
- Read a `HelmRelease` with `driftDetection`.
- Clone, change, commit and push with `git`.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- The namespaces `podinfo-staging` and `podinfo-production`.
- The Flux `Kustomization` `podinfo-staging`, the `HelmRepository` `podinfo` and the `HelmRelease` `podinfo` in `podinfo-production`, prepared as the task describes. The environment needs outbound internet.
- In the repository, `apps/podinfo/base` as the task describes.

## Working rules

- Everything is graded on the **final state** of the cluster and the repository, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- Some faults are in Git. Change them with a commit and a push from your clone (the port-forward must run), never with `kubectl` on the application.
