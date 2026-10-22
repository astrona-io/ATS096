# Keep The Cluster Equal To Git

During an incident, someone scales a Deployment to five replicas and adds a label to find its pods. A week earlier, a teammate deleted a ConfigMap file from Git. Which of these does Flux undo, which does it leave, and which does it never notice? The answer differs between kustomize-controller and helm-controller, and that difference surprises most teams the first time it matters.

**Drift** is any difference between the live state of an object and the state Git describes. **Pruning** is deleting objects that Flux applied before and that are no longer in Git. A Flux `Kustomization` (the Flux object, not the Kustomize file `kustomization.yaml`) corrects drift and prunes on every reconciliation. A `HelmRelease` does neither by default: helm-controller only acts when the chart or the values change, unless you turn drift detection on.

Keep one sentence in mind: **kustomize-controller corrects drift on every reconciliation, and helm-controller only when you ask it to.** Every command in this module tests that sentence.

The module has three parts. **Drift Correction With Server-Side Apply** changes the staging Deployment by hand and shows what kustomize-controller puts back and what it leaves. **Pruning, The Inventory And Deletion Policies** adds and removes a file in Git and follows the object through the inventory. **Drift Detection In helm-controller** scales production by hand and turns on drift detection, with an exception for one field. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain how kustomize-controller detects drift with a server-side apply dry run, and read field managers on a live object.
- Predict which manual changes a Flux `Kustomization` reverts and which it keeps.
- Choose between the `ssa` annotation values `Override`, `Merge`, `IfNotPresent` and `Ignore`, and the `prune` and `reconcile` annotations.
- Read the inventory of a Flux `Kustomization` and explain what pruning deletes.
- Choose a deletion policy for a Flux `Kustomization`.
- Turn on drift detection in a `HelmRelease` with `warn` or `enabled`, and exclude a field with an ignore rule.

## Before you start

You need Kubernetes basics (Deployments, labels, `kubectl scale`, `kubectl edit`) and basic Git (`clone`, `commit`, `push`). You should know that a Flux `Kustomization` applies a folder of a Git source, and that a `HelmRelease` installs a Helm chart with helm-controller.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| Flux `Kustomization` `podinfo-staging` | Applies `./apps/podinfo/base` from the `GitRepository` `fleet` into `podinfo-staging`, with pruning on and the message `staging` |
| `HelmRelease` `podinfo` (namespace `podinfo-production`) | Installs chart podinfo `6.15.0` from the `HelmRepository` `podinfo`, with 2 replicas and the message `production`. No drift detection |
| `gitops/fleet` | The base `apps/podinfo/base`: a Deployment and a Service for podinfo |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs. The lab-only user is `gitops` with the password `gitops-password`. The Flux objects were applied with `kubectl`; on a real cluster they live in Git, under `clusters/<cluster name>/`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
