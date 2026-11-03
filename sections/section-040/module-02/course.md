# Share Fields Between Flux And Other Controllers

Git does not describe everything on a live object. Autoscalers change replica counts, admission webhooks add annotations, operators write defaults, and people tune values during incidents. If Flux claims every field it is allowed to claim, it fights each of them. This module explains how Kubernetes decides who owns a field, how Flux takes part in that decision, and how to leave a field to another writer on purpose.

Keep one sentence in mind: **Flux owns exactly the fields that appear in the YAML it applies.** To give a field to someone else, take it out of the YAML. To take a field back, put it in.

The module has four parts. **Reading Field Ownership** looks at the ownership records of a Deployment. **Letting Another Writer Own A Field** removes `replicas` from Git so that a second writer can set it. **Conflicts And Forced Changes** shows what happens when two writers claim the same field and what Flux does about it. **Choosing The Smallest Exception** compares the ways to keep a field out of Flux, from narrow to wide. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Read `managedFields` and say which manager owns a given field.
- Explain why a field removed from Git stops being owned by Flux.
- Give a field to an autoscaler or to a person without breaking the Flux `Kustomization`.
- Explain a server-side apply conflict and how Flux resolves it.
- Choose the narrowest exception from a set of options.

## Before you start

You need the previous module on drift correction: a Flux `Kustomization` corrects drift with server-side apply, and a manual change to a field that Git sets lasts at most one `interval`. You should be able to clone a repository, commit and push.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| Flux `Kustomization` `podinfo-staging` | Applies `./apps/podinfo/base` from the `GitRepository` `fleet` into `podinfo-staging`, with pruning on |
| `gitops/fleet` | The base `apps/podinfo/base`: a Deployment with `replicas: 1`, and a Service |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs. The user is `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
