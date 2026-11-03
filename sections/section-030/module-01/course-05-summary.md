# Summary

Flux installs Helm charts with two controllers and three kinds of object. You describe the chart and the values; helm-controller runs every install and upgrade, keeps the history, and decides what to do when one fails.

## What you learned

source-controller fetches charts. A `HelmRepository` points at a chart repository and downloads its `index.yaml`; a `HelmChart`, which helm-controller creates from `spec.chart` in the namespace of the `HelmRepository`, holds one chart version as an artifact. An `OCIRepository` fetches a chart from an OCI registry, selected by tag and layer media type, and a `HelmRelease` uses it through `spec.chartRef`. A `HelmRelease` has exactly one of `chart` and `chartRef`, and a missing chart version shows on the source or the `HelmChart` before it shows on the release.

helm-controller installs them. The `HelmRelease` names the chart, the `releaseName` and the values. Values come from `valuesFrom`, ConfigMaps and Secrets in the release's namespace merged in list order, with `valuesKey` defaulting to `values.yaml` and `targetPath` setting one value; inline `values` are merged last and win. A change to a values source is read at the next reconciliation. The release shows in `flux get helmreleases`, in the `HelmRelease` status history, and in Helm's storage Secrets `sh.helm.release.v1.<release>.v<N>`, whose `status` label says `deployed`, `superseded` or `failed`.

Remediation handles failure. An install or upgrade fails when the chart cannot render, an object is refused, or the resources are not ready within `timeout`. `upgrade.remediation.retries` and the strategy `rollback` or `uninstall` decide what happens next; when the retries run out, the release is `Stalled` with `RetriesExceeded` and waits for a change. Changing the values, the chart version or the spec resets the counters, so the way out is always a fix. The key facts to remember are these:

- source-controller fetches the chart; helm-controller installs it.
- Inline `values` win over `valuesFrom`.
- Remediation is off until you set `retries`.
- Helm's storage Secrets are the full record of every revision, including the failed ones.

<!-- astrona:playground:destroy -->
