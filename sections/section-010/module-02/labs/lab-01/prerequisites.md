# Prerequisites

Before starting this lab you should be able to:

- Read a Kustomize file `kustomization.yaml` with `resources`, `namespace` and `configMapGenerator`.
- Clone, edit, commit and push a Git repository.
- Use `flux get kustomizations` and `flux reconcile`.
- Send a request from one pod to another with `kubectl exec` and `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- In the repository, the folder `apps/podinfo/base` and the overlay `apps/podinfo/overlays/staging`, which lists a plain ConfigMap file.
- The Flux `Kustomization` `podinfo-staging`, already `Ready`, applying the staging overlay into the namespace `podinfo-staging`.

## Working rules

- Everything is graded on the **final state** of the cluster, so check `flux get` at the end and leave the fix in place.
- The change belongs in Git. Do not change the live objects with `kubectl`.
- Change one thing at a time and check again.
