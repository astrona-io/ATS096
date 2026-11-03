# Summary

A Flux `Kustomization` calls its objects healthy by reading their status. For built-in kinds this works. For a custom resource, kustomize-controller looks for a `Ready` condition and calls the object healthy when none exists, so a stage can become `Ready` while the object does nothing.

`healthCheckExprs` gives Flux the rule. Each entry names a kind and holds the CEL expressions `inProgress`, `failed` and `current`, tried in that order, and the first true one decides. The objects to judge come from `healthChecks` or from `wait: true`; with `wait: true` the list `healthChecks` is ignored. A `failed` expression turns a long wait into an immediate `HealthCheckFailed`.

A rule is tested by writing the status by hand with `kubectl patch --subresource=status`, once for a healthy value and once for a value that must fail. Fields that may be missing are protected with `has()`. The common patterns are a condition read with `filter` and `exists`, a counter compared with the spec, and `observedGeneration` compared with `metadata.generation`, which protects against a stale status.

- Without a rule, a custom resource without status counts as healthy.
- The expressions are tried in the order `inProgress`, `failed`, `current`.
- Test every rule with a value that must pass and a value that must fail.

<!-- astrona:playground:destroy -->
