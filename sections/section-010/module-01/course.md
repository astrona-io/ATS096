# Shape What Flux Applies With The Flux Kustomization

The repository holds one folder for the `podinfo` application. Staging and production both need it, but not in the same form: production runs more replicas, and each environment shows its own message and carries its own label. Copying the folder per environment works for a week. After that, a fix lands in one copy and not the other.

Flux solves this without copies. A Flux `Kustomization` is the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`: it tells kustomize-controller which folder to build and how to change the result before it applies it. It is not the Kustomize file `kustomization.yaml`, which lives inside the folder and lists its files. Two Flux `Kustomization` objects can point at the same folder and produce two different results.

Keep one sentence in mind: **the folder in Git is the base, and each Flux `Kustomization` is the overlay for one environment.** Every command in this module tests that sentence.

The module has three parts. **The Flux Kustomization And Kustomize** follows one build through kustomize-controller and previews it with `flux build` and `flux diff`. **Target Namespaces And Patches** deploys the base into a second namespace and changes the replica count and a label with patches. **Variable Substitution After The Build** sets a message and a label per environment from inline values and from a ConfigMap. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Describe the steps kustomize-controller runs on a folder, and say which step the Kustomize command-line tool does not run.
- Preview a build with `flux build kustomization` and compare it with the cluster with `flux diff kustomization`.
- Deploy one folder into two namespaces with `targetNamespace`, and explain why the namespace must already exist.
- Write a strategic merge patch and a JSON6902 patch, and choose their target by kind and name.
- Set values per environment with `postBuild.substitute` and `postBuild.substituteFrom`, and use `${var:=default}`.
- Explain what happens when a variable source is missing, and why `optional: true` can hide a mistake.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Services, labels, ConfigMaps) and basic Git (`clone`, `commit`, `push`). You should know what a `GitRepository` and a Flux `Kustomization` are for: the first makes source-controller fetch a repository, and the second makes kustomize-controller apply a folder of it.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| `GitRepository` `fleet` | Already `Ready`. It follows the branch `main` of the repository `gitops/fleet`, with the credentials in the Secret `fleet-auth` |
| `gitops/fleet` | The folder `apps/podinfo/base` holds a Deployment and a Service for `podinfo`, and a Kustomize file `kustomization.yaml` that lists them. The Deployment uses the variables `${environment}` and `${message}` |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

No Flux `Kustomization` exists yet. The pages apply them with `kubectl` from files you save, so that you see the whole object. On a real cluster these objects live in Git too, under a folder such as `clusters/<cluster name>/`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs in a second terminal. The server uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
