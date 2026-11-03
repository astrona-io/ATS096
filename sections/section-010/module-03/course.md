# Replacements And Debugging Builds

A build can go wrong in two places. The Kustomize file can describe something that cannot be built, and the Flux `Kustomization` can build fine but fail to apply. When that happens in a cluster, nobody sits at a terminal watching the controller. You find out later, from a status message, and you must know where to look and in what order.

This module has two halves. The first teaches **replacements**, the Kustomize feature that copies a value from one object into another inside the build. The second teaches the debugging tools: previewing a build before it reaches the cluster, reading the status, events and logs of kustomize-controller, and following a live object back to the Git commit it came from.

Keep one sentence in mind: **a failed Flux `Kustomization` always says which step failed, and the same step can be reproduced on your machine.** Every command in this module tests that sentence.

The module has four parts. **Replacements** copies the message from a ConfigMap into a Deployment without a variable. **Preview Builds Locally** compares `kubectl kustomize`, `flux build kustomization` and `flux diff kustomization`. **Read Kustomize Controller Errors** reads the status, the events and the logs, and connects each failure reason to a step. **Trace And Debug Workflow** follows a live object to its source and ends with an order of checks. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Write a replacement with a `source`, a `target`, a `select` and a `fieldPath`, and say how it differs from variable substitution.
- Preview a build with `kubectl kustomize`, with `flux build kustomization` and with `flux diff kustomization`, and say what each one shows.
- Read the Ready condition, the events and the logs of a Flux `Kustomization`, and name the step each failure reason points to.
- Tell the revision Flux applied from the revision it tried to apply.
- Follow a live object back to its Flux `Kustomization` and its Git source with `flux trace` and with field managers.
- Apply a fixed order of checks to a Flux `Kustomization` that is not `Ready`.

## Before you start

You need Kubernetes basics (namespaces, Deployments, ConfigMaps, environment variables), basic Git (`clone`, `commit`, `push`) and the idea of a Flux `Kustomization` with `path`, `sourceRef` and `targetNamespace`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| `GitRepository` `fleet` | Already `Ready`. It follows the branch `main` of the repository `gitops/fleet`, with the credentials in the Secret `fleet-auth` |
| `gitops/fleet` | The folder `apps/podinfo/base` holds a Deployment and a Service for `podinfo`. The folder `apps/podinfo/overlay` adds a ConfigMap `podinfo-settings` and a replacement that copies its message into the Deployment |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

No Flux `Kustomization` exists yet. The pages apply them with `kubectl` from files you save, so that you see the whole object. On a real cluster these objects live in Git too, under a folder such as `clusters/<cluster name>/`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs in a second terminal. The server uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
