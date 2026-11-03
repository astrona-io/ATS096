# Move And Remove Objects Safely

Deleting a file from Git deletes an object. Usually that is what you want. It is a problem when the file only moved to another folder, or when the object is shared and other workloads still read it. This module explains how a Flux `Kustomization` knows which objects are its own, what it deletes, and how to move or remove objects without surprises.

Keep one sentence in mind: **a Flux `Kustomization` deletes only objects it recorded as its own and that are not in the new build.** The inventory records them, and labels on the objects say whose they are.

The module has four parts. **The Inventory In Detail** reads the record and the labels. **What Pruning Deletes And What It Skips** sets the exact rule and the annotation that protects an object. **Moving An Object Between Stages** moves a ConfigMap between two stages without recreating it. **Deleting A Stage** shows what happens to the objects when the Flux `Kustomization` itself is deleted. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Read the inventory and the owner labels of an object.
- State what pruning deletes and what it never deletes.
- Move an object from one Flux `Kustomization` to another without recreating it.
- Delete a Flux `Kustomization` and predict what remains.

## Before you start

You need the previous module on drift and pruning: a Flux `Kustomization` records what it applied, and removing a file from Git deletes the object when `prune: true`. You should be able to clone, commit and push.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| Flux `Kustomization` `podinfo-staging` | Applies `./apps/podinfo/base` from the `GitRepository` `fleet` into `podinfo-staging`, with pruning on |
| `gitops/fleet` | The base `apps/podinfo/base` |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs. The user is `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
