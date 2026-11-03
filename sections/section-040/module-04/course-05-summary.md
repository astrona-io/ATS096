# Summary

helm-controller applies a Helm release and does not look at the live objects unless drift detection is on. With `driftDetection.mode: warn` it compares each object with the manifest of the last release and reports differences in the `Drifted` condition and in events. With `mode: enabled` it also applies the release manifest again to the objects that differ.

A rule in `driftDetection.ignore` removes fields from the comparison. Each rule has JSON Pointer paths and an optional target that selects objects by kind, name, namespace and selectors. A rule without a target applies to every object that has the path, and a path with a typo matches nothing and gives no error. Test every rule by changing the field by hand and reconciling.

A field that another controller writes, such as the replicas set by an autoscaler, needs an ignore rule on that field and on that kind of object. The release keeps correcting every other field. Switching correction off to avoid the fight removes protection from the whole release.

A `HelmRelease` is also an object that people can edit. Only a Flux `Kustomization` that applies it from Git keeps its spec equal to Git.

<!-- astrona:playground:destroy -->
