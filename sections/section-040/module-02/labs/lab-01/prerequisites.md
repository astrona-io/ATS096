# Prerequisites

Before starting this lab you should be able to:

- Explain what server-side apply and a field manager are.
- Read `metadata.managedFields` with `--show-managed-fields`.
- Clone the repository, commit and push.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The `GitRepository` `fleet` in `flux-system`, already `Ready`.
- The Flux `Kustomization` `podinfo-staging`, which runs podinfo in `podinfo-staging` with `replicas: 1`.

## Working rules

- Everything is graded on the final state of the cluster and the repository.
- Change one thing at a time and check again.
