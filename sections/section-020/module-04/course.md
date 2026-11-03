# Order Kustomizations Around HelmReleases And CRDs

`dependsOn` orders Flux `Kustomization` objects among themselves, and a `HelmRelease` can order itself behind other `HelmRelease` objects. Real clusters need more than that: a chart that installs custom resource definitions must finish before the objects that use them, and an application stage must wait for a chart that another stage installs. This module shows how to build those orders from the pieces Flux has.

Keep one sentence in mind: **`dependsOn` links objects of the same kind, so across kinds the order comes from a health check.** A stage that applies a `HelmRelease` becomes `Ready` only when the release is healthy, and a second stage waits for that stage.

The module has four parts. **The Problem Of Order Across Kinds** shows the error that appears when an object is applied before its definition. **A HelmRelease Inside A Gated Kustomization** installs a chart from a stage that waits for the release. **Ordering HelmRelease Objects** uses `dependsOn` between releases. **CRDs And Their Custom Resources** orders the definitions of a chart before the objects that use them. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain why an object applied before its definition fails, and recognize the error.
- Make a Flux `Kustomization` wait for a `HelmRelease` that another Flux `Kustomization` applies.
- Add a `dependsOn` entry to a `HelmRelease`, by name and namespace.
- Split definitions and custom resources into two ordered stages.
- Choose between ordering within one folder and ordering across stages.

## Before you start

You need Kubernetes basics (namespaces, custom resource definitions) and basic Git (`clone`, `commit`, `push`). You should know that a Flux `Kustomization` (the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`, not the Kustomize file `kustomization.yaml`) applies a folder of a Git source, and that a `HelmRelease` installs a Helm chart with helm-controller.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system`, including helm-controller |
| `GitRepository` `fleet` | Already `Ready`, following the branch `main` of `gitops/fleet` |
| `gitops/fleet` | The folders `infrastructure/redis` and `apps/podinfo/base` |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |
| Internet access | The chart comes from `https://stefanprodan.github.io/podinfo` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal. The user is `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
