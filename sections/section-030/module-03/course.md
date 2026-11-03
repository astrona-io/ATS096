# Values And Post-Rendering

A chart is a template. The values you give it, and the changes you make to its output, decide what runs in the cluster. This module follows the path from a value to a running object: where a value can come from, which one wins when two sources disagree, how to change a chart's output when its values do not reach far enough, and how to look at what Helm really rendered.

Keep one sentence in mind: **helm-controller builds one values document, renders the chart with it, optionally rewrites the result, and installs what is left.** Each part of this module is one step in that sentence.

The module has four parts. **Values From ConfigMaps And Secrets** reads values from objects in the cluster. **Merge Order And Precedence** shows which source wins. **Post-Renderers** rewrites rendered manifests with Kustomize patches. **Helm Tests And Inspecting The Output** runs a chart's tests and decodes the rendered result from Helm's storage. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Take values from a ConfigMap or a Secret with `valuesFrom`, as a whole document or into one `targetPath`.
- Say in which order values are merged, and predict the winner of a conflict.
- Patch rendered manifests with a Kustomize post-renderer.
- Run the tests of a chart with `spec.test`.
- Read the rendered manifest of a release from Helm's storage Secret.

## Before you start

You need Kubernetes basics (namespaces, ConfigMaps, Secrets) and the content of the module on chart sources: a `HelmRepository` and a `HelmRelease`. The `helm` command is not needed.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system`, including helm-controller |
| `GitRepository` `fleet` | Already `Ready`, following the branch `main` of `gitops/fleet` |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |
| Internet access | The chart comes from `https://stefanprodan.github.io/podinfo` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
