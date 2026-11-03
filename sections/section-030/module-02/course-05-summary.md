# Summary

A `HelmRelease` gets its chart through a chain of objects. A `HelmRepository` or an `OCIRepository` or a `GitRepository` is the source, source-controller turns a chart from it into an artifact through a `HelmChart`, and helm-controller installs the artifact. When a release does not install, the first check is whether the `HelmChart` is `Ready`, because helm-controller has nothing to install without it.

The version in `spec.chart.spec.version` is an exact version or a semantic version constraint, and source-controller selects the highest match. A range lets the cluster change without a commit, so it fits development stages and not production. The reconcile strategy decides when a changed chart is new: `ChartVersion` only when the version in `Chart.yaml` changes, and `Revision` on every new revision of the source, which is right for a chart under development in Git.

A chart in a `GitRepository` is installed with `chart` as a path and `sourceRef` to the repository. `valuesFiles` selects files of the chart folder that are merged over `values.yaml` in order, and `spec.values` of the release wins over all of them.

source-controller can verify the cosign signature of an OCI chart with `verify`, an issuer pattern and a subject pattern, and refuses an artifact that does not match. A `secretRef` gives a source its credentials from a Secret in the same namespace.

- The `HelmChart` sits between the source and the release.
- A range is a risk; an exact version is a decision.
- Use `Revision` for charts in Git that change often.
- Keep identity patterns narrow, and credentials encrypted in Git.

<!-- astrona:playground:destroy -->
