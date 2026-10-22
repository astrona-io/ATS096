# Deploy Helm Charts With HelmRelease

The podinfo chart has more than a hundred values: replicas, the message, the image tag, the Service type, probes, resources. Staging and production need different values for a handful of them. Running `helm upgrade --install` by hand for each environment works until someone forgets a `--set`, and nobody can say afterwards which values production runs with.

With Flux, the values live in objects, and helm-controller runs the install and every upgrade. A **`HelmRelease`** is the Flux object `helm.toolkit.fluxcd.io/v2` `HelmRelease`: it names a chart, a version and the values, and helm-controller makes the release in the cluster match it. A **release** is one installed copy of a chart, and every install or upgrade adds a numbered revision to its history.

Keep one sentence in mind: **source-controller fetches the chart, and helm-controller installs it.** When a release does not work, the first question is always which of the two failed.

The module has three parts. **From HelmRepository To HelmRelease** installs the chart into staging and reads the release from every side. **Values, valuesFrom And OCI Chart Sources** moves the values into a ConfigMap and installs production from an OCI registry. **Failed Upgrades, Remediation And Rollback** pushes an upgrade that cannot work and lets helm-controller roll it back. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Create a `HelmRepository` and a `HelmRelease`, and name the `HelmChart` that helm-controller creates between them.
- Read a release with `flux get helmreleases`, the status history and Helm's storage Secrets.
- Give a release its values inline, from a ConfigMap and from a Secret, and predict which value wins.
- Install a chart from an OCI registry with an `OCIRepository` and `chartRef`.
- Configure install and upgrade remediation, and explain retries, rollback, uninstall and `Stalled`.
- Recover a release after a failed upgrade by fixing its values.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Services, ConfigMaps, Secrets) and you should know what a Helm chart is: templates plus a `values.yaml` file of defaults. You do not need the `helm` command; the playground does not install it, and everything here reads the release from Flux and Kubernetes objects.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system`, including helm-controller |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |
| Internet access | The chart comes from `https://stefanprodan.github.io/podinfo` and `oci://ghcr.io/stefanprodan/charts/podinfo` |

The playground also runs Gitea and the `GitRepository` `fleet`, which this module does not use. The Flux objects are applied with `kubectl` from files you save; on a real cluster they live in Git, under `clusters/<cluster name>/`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
