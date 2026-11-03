# Summary

A release has three places: the namespace of the `HelmRelease` object, `spec.targetNamespace` for the objects of the chart, and `spec.storageNamespace` for Helm's Secrets. `install.createNamespace` creates a missing target namespace. The release name defaults to the target namespace joined to the object name, so set `releaseName` when the name matters. The name and the storage namespace are part of the identity of a release and are not changed on a live one.

`spec.maxHistory` limits the stored revisions, 5 by default; keep at least two for rollback. `spec.timeout` is 5 minutes by default, and `install.timeout`, `upgrade.timeout` and `uninstall.timeout` override it. `disableWait` stops Helm from waiting for readiness and needs another check in its place.

CRDs follow the policies `Skip`, `Create` and `CreateReplace`: `Create` is the default on install, and `Skip` is the default on upgrade. `cleanupOnFail` removes objects of a failed upgrade, `force` recreates objects that cannot be patched, and `preserveValues` should stay off in GitOps. `flux reconcile helmrelease --reset` clears the failure count and `--force` runs the action again.

Deleting a `HelmRelease` runs an uninstall through a finalizer. The chart's objects and Helm Secrets are removed, the namespace stays, and `uninstall.keepHistory` keeps the record. Suspend before handing a release to another tool.

- Decide name and storage once.
- Keep history short but not too short.
- Update CRDs on purpose.
- Delete means uninstall.

<!-- astrona:playground:destroy -->
