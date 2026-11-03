# Prerequisites

Before starting this lab you should be able to:

- Read the status and events of a Flux `Kustomization` with `flux get` and `kubectl describe`.
- Edit a Kubernetes object with `kubectl edit` or `kubectl patch`.
- Explain what SOPS and age are used for.
- Send a request from one pod to another with `kubectl exec` and `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`).
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- **age** and **sops** on your PATH, and the Secret `sops-age` in `flux-system` that holds the age private key under `age.agekey`.
- In the repository, the folder `apps/podinfo/base` with a Deployment, a Service and the encrypted file `secret.sops.yaml`.
- The Flux `Kustomization` `podinfo-secure`, which applies that folder into the namespace `podinfo-staging`.

## Working rules

- Everything is graded on the **final state** of the cluster, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again.
