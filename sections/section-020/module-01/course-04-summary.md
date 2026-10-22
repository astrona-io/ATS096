# Summary

Flux reconciles every Flux `Kustomization` on its own, in no order, and by default calls it `Ready` as soon as its objects are stored. Dependencies and health checks turn separate Flux objects into a pipeline that applies in order and only goes ahead when the stage before it really runs.

## What you learned

`dependsOn` lists other Flux `Kustomization` objects by name, and by namespace when they live elsewhere. Before each reconciliation, kustomize-controller checks their `Ready` condition. If one is not ready, or does not exist, it applies nothing, reports the reason `DependencyNotReady`, and tries again after `retryInterval`. Creation order does not matter, loops wait forever, and a typo in a name looks exactly like a dependency that is not ready.

Health checks decide what `Ready` means. `wait: true` checks every applied object, `healthChecks` checks a list of named objects and is ignored when `wait` is on, and `healthCheckExprs` judges custom resources with CEL expressions tried in the order `inProgress`, `failed`, `current`. When the workloads are not healthy within `timeout`, the object reports `HealthCheckFailed`. Flux undoes nothing: the Deployment keeps its old pods, and the failure shows in the `Ready` condition that dependents read.

Together they make a staged pipeline. Infrastructure, staging and production each check health, and each waits for the one before. A bad commit fails its health check in staging, and production refuses to apply anything while staging is not ready, so it keeps the last good version. The fix is another commit, such as a revert. The key facts to remember are these:

- `dependsOn` waits for `Ready`; health checks decide what `Ready` means.
- A dependency without a health check gives order but no protection.
- `timeout` is the budget for one reconciliation; `retryInterval` is the pause after a failure.
- The gate is health, not approval. Promotion by hand needs its own branch or tag.

<!-- astrona:playground:destroy -->
