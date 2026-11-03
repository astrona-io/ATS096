# Build Environments With Kustomize Files

The repository now holds more than one folder per application. There is a base, one overlay folder per environment, and a small folder of reusable changes. Each folder has a Kustomize file `kustomization.yaml` that says how to build it. The Flux `Kustomization` object then points at one of those folders and applies the result.

Two things carry the work here, and it helps to keep them apart. The Kustomize file `kustomization.yaml` is the configuration file of the Kustomize tool, which builds a folder into final manifests. The Flux `Kustomization` is the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`, which tells kustomize-controller which folder of a source to build and apply. This module is about the first one: what you can put in the file, and how Flux reacts to it.

Keep one sentence in mind: **the Kustomize file decides what is built, and the Flux `Kustomization` decides where the result is applied.** Every command in this module tests that sentence.

The module has four parts. **Bases And Overlays** builds one overlay folder per environment and points a Flux `Kustomization` at each. **Images, Replicas And Labels** uses the transformers of the Kustomize file that change an image, a replica count and labels without a patch. **Generators And Hash Suffixes** makes a ConfigMap and a Secret from literals, and shows why a changed generator rolls the pods. **Components** packages a change once and adds it to the overlays that need it. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Build an overlay folder that reuses a base with `resources`, and point a Flux `Kustomization` at it.
- Preview any folder with `kubectl kustomize` and read the result.
- Change images, replica counts, namespaces and labels with the transformers of the Kustomize file.
- Create a ConfigMap and a Secret with `configMapGenerator` and `secretGenerator`, and explain the hash suffix in their names.
- Explain why a changed generator rolls the pods and a changed plain ConfigMap does not.
- Write a Kustomize `Component` and add it with `components`, both in the Kustomize file and in the Flux `Kustomization`.

## Before you start

You need Kubernetes basics (namespaces, Deployments, ConfigMaps, Secrets, labels), basic Git (`clone`, `commit`, `push`) and the idea of a Flux `Kustomization` with `path`, `sourceRef` and `targetNamespace`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| `GitRepository` `fleet` | Already `Ready`. It follows the branch `main` of the repository `gitops/fleet`, with the credentials in the Secret `fleet-auth` |
| `gitops/fleet` | The folder `apps/podinfo/base` holds a Deployment and a Service for `podinfo`. The folders `apps/podinfo/overlays/staging` and `apps/podinfo/overlays/production` reuse it, and `apps/podinfo/components/resource-limits` holds a Kustomize component |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

No Flux `Kustomization` exists yet. The pages apply them with `kubectl` from files you save, so that you see the whole object. On a real cluster these objects live in Git too, under a folder such as `clusters/<cluster name>/`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs in a second terminal. The server uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
