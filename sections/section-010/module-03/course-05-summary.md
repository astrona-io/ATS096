# Summary

A build can fail at a known step, and Flux names that step. Replacements move values inside a build, and a small set of commands shows the result before and after it reaches the cluster.

## What you learned

A replacement is an entry in the `replacements` field of a Kustomize file. It reads a `fieldPath` of a source object and writes it into the `fieldPaths` of the target objects chosen by `select`. A path segment such as `[name=podinfo]` picks a list item by name. The `options` `create`, `delimiter` and `index` create a missing field or replace one part of a string. A replacement copies between objects that are both in the build, and variable substitution brings in values from outside the build. A source key that does not exist is a build error, and a target that selects nothing is silent.

`kubectl kustomize` runs only the Kustomize build. `flux build kustomization` adds the fields of the Flux `Kustomization` and replaces variables, and `flux diff kustomization` compares the result with the cluster and exits with `1` on differences. With `--dry-run` and `--kustomization-file`, `flux build` works without a cluster, and `--strict-substitute` turns a variable without a value into an error.

When a Flux `Kustomization` fails, the Ready condition holds a reason that names the step. `ArtifactFailed` points to the source, `BuildFailed` to the Kustomize build or the substitution, `ReconciliationFailed` to the apply, `HealthCheckFailed` to the health checks, `DependencyNotReady` to `dependsOn` and `PruneFailed` to the deletion of objects that left Git. The same message appears in the status, in `flux events` and in the log of kustomize-controller. The applied revision is the last good one, and the attempted revision is the one that was tried last. The objects of the last good revision keep running.

`flux trace` walks from a live object back to its Flux `Kustomization` and its Git source. The inventory lists what a Flux `Kustomization` applied, and the managed fields show which client changed a field. The key facts to remember are these:

- The reason in the Ready condition names the failed step.
- A build error is reproduced on your machine; an apply error is not.
- After a push, reconcile with `--with-source`.
- Compare the attempted revision with the applied revision.

<!-- astrona:playground:destroy -->
