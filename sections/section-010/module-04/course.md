# Securing And Sourcing Kustomizations

A Flux `Kustomization` can do more than build a folder and apply it. It can decrypt secrets that are stored in Git, it can apply objects with the permissions of a limited account instead of cluster administrator, it can read its files from more places than a Git repository, and it can be paused. These options decide who can change what, and what an attacker or a mistake can reach.

Two things carry the work here, and it helps to keep them apart. The Kustomize file `kustomization.yaml` is the configuration file of the Kustomize tool, which builds a folder into final manifests. The Flux `Kustomization` is the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`, which tells kustomize-controller which folder of a source to build and apply. This module is about the second one: the fields `decryption`, `serviceAccountName`, `sourceRef` and `suspend`.

Keep one sentence in mind: **a Flux `Kustomization` applies what its source holds, with the permissions of the account it runs as, so both the source and the account need protection.** Every part of the module tests that sentence.

The module has four parts. **Decrypt Secrets With SOPS And Age** keeps an encrypted Secret in Git and lets kustomize-controller decrypt it. **Impersonate A Service Account** limits what one Flux `Kustomization` can change in the cluster. **Source Kinds And Cross-Namespace References** points a Flux `Kustomization` at a `GitRepository`, an `OCIRepository` or a `Bucket`, and at a source in another namespace. **Suspend, Resume And Reconcile Controls** pauses and restarts reconciliation without deleting anything. A graded lab follows the first part.

## Learning objectives

After this module you can:

- Create an age key pair, store the private key as a Secret, and encrypt only the data of a Kubernetes Secret with SOPS.
- Add a `decryption` block to a Flux `Kustomization` and explain what happens without it.
- Set `serviceAccountName` so that a Flux `Kustomization` applies objects with limited permissions, and read the error when the permissions are too small.
- Choose between the source kinds `GitRepository`, `OCIRepository` and `Bucket`, and point `sourceRef` at one, including one in another namespace.
- Suspend and resume a Flux `Kustomization`, and force a fresh reconcile with and without a source refresh.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Secrets, ServiceAccounts, Roles), basic Git (`clone`, `commit`, `push`) and the idea of a Flux `Kustomization` with `path`, `sourceRef` and `targetNamespace`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| age 1.2.1 and sops 3.9.4 | The tools that create keys and encrypt files, on your PATH |
| `GitRepository` `fleet` | Already `Ready`. It follows the branch `main` of the repository `gitops/fleet`, with the credentials in the Secret `fleet-auth` |
| `gitops/fleet` | The folder `apps/podinfo/base` holds a Deployment and a Service for `podinfo`. The Deployment reads its message from a Secret named `podinfo-credentials` that does not exist yet |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

No Flux `Kustomization` exists yet. The pages apply them with `kubectl` from files you save, so that you see the whole object. On a real cluster these objects live in Git too, under a folder such as `clusters/<cluster name>/`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs in a second terminal. The server uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
