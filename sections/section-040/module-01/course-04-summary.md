# Summary

The cluster drifts away from Git in two ways: a live object changes by hand, or a file leaves Git while its object stays. kustomize-controller handles both on every reconciliation. helm-controller handles neither until you ask it to.

## What you learned

kustomize-controller applies every object with server-side apply, so the API server records which field manager set which field. On each reconciliation it runs a dry run, and when the result differs from the live object it applies for real and takes back the fields that came from Git. A manual change to such a field lasts at most one `interval`. Fields added with `kubectl` are removed too, unless they were added with the field manager `flux-client-side-apply`. The annotation `kustomize.toolkit.fluxcd.io/ssa` makes exceptions per object: `Override` is the default, `Merge` keeps fields from other managers, `IfNotPresent` only creates, and `Ignore` never applies. `reconcile: disabled` pauses one object, and `force` recreates objects whose immutable fields changed.

Pruning works from the inventory, the list of objects in `.status.inventory` that the last successful reconciliation applied. With `prune: true`, objects on the list and not in the new build are deleted. The annotation `prune: disabled` keeps one object. With `prune: false`, removed files leave objects behind that drop off the inventory, and turning pruning on later does not delete them. `deletionPolicy` decides what happens when the Flux `Kustomization` itself is deleted: `MirrorPrune`, `Delete`, `WaitForTermination` or `Orphan`.

helm-controller only upgrades when the chart or the values change, so by default a manual change to a release's objects stays. `driftDetection.mode: warn` reports drift in the `Drifted` condition and the events; `enabled` corrects it on every reconciliation. `driftDetection.ignore` excludes fields by JSON Pointer, optionally for a `target` such as one kind. The key facts to remember are these:

- kustomize-controller corrects drift by default; helm-controller only with `driftDetection.mode: enabled`.
- Pruning deletes only what is on the inventory.
- Every annotation and ignore rule is a hole in the guarantee; keep each one narrow and deliberate.

<!-- astrona:playground:destroy -->
