# Choose And Pin Chart Sources

A `HelmRelease` is only as predictable as the chart it installs. Which chart version does a release get when you write `6.x`? Does a change to a chart in Git reach the cluster when the version number in `Chart.yaml` stays the same? Can helm-controller prove that a chart was signed by the project that published it? This module answers these questions by following the chart from its source to the release.

Keep one sentence in mind: **source-controller fetches and packages the chart, and helm-controller installs what it packaged.** Every setting in this module changes what source-controller delivers.

The module has four parts. **The HelmChart Between Source And Release** shows the object that sits between the two. **Versions And Reconcile Strategy** pins a version and chooses when a new revision counts. **Charts From Git** installs a chart that lives in the repository, with values files. **Verifying And Authenticating Charts** checks the signature of an OCI chart and reads a chart repository that needs a login. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Name the `HelmChart` that helm-controller creates, and read its artifact and revision.
- Write an exact version, a semantic version range and a wildcard, and say what each one selects.
- Choose between the reconcile strategies `ChartVersion` and `Revision`.
- Install a chart from a path in a `GitRepository` and select values files from the chart.
- Verify the signature of an OCI chart with cosign, and give a chart repository credentials.

## Before you start

You need Kubernetes basics (namespaces, ConfigMaps) and basic Git (`clone`, `commit`, `push`). You should know what a Helm chart is: templates plus a `values.yaml` file of defaults. The `helm` command is not needed.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system`, including helm-controller |
| `GitRepository` `fleet` | Already `Ready`, following the branch `main` of `gitops/fleet` |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |
| Internet access | The chart comes from `https://stefanprodan.github.io/podinfo` and `oci://ghcr.io/stefanprodan/charts/podinfo` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal. The user is `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
