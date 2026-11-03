# Summary

`dependsOn` orders objects of the same kind: Flux `Kustomization` objects among themselves, and `HelmRelease` objects among themselves. Across kinds, the order comes from health. A Flux `Kustomization` that applies a `HelmRelease` with `wait: true` is `Ready` only when the release is healthy, and a second stage that depends on it waits for the chart.

An object applied before its definition fails with the message that no matches for the kind exist. Inside one folder kustomize-controller applies definitions and namespaces first, so a definition and its objects can share a Flux `Kustomization`. Definitions from a chart or from another folder need two stages: the first applies them and waits until they are established, and the second applies the objects and depends on the first.

A `HelmRelease` can wait for other releases with `dependsOn`, by name and namespace. helm-controller reads their `Ready` condition and shows `DependencyNotReady` while they wait. Use release ordering for details inside a stage and stage ordering for the big picture. Deleting a definition from Git deletes every object of that kind.

- A health check is the bridge between kinds.
- A gated chart stage needs `wait: true` and a `timeout` that covers the install.
- Definitions come first, objects second, and pruning goes the other way round.

<!-- astrona:playground:destroy -->
