# Summary

The Kustomize file `kustomization.yaml` and the Flux `Kustomization` share a name but have separate jobs. The Kustomize file in Git decides what is built from a folder. The Flux `Kustomization` decides which folder and source kustomize-controller builds, and where and how the result is applied.

## What you learned

A base holds the common objects of an application, and an overlay lists the base under `resources` with a relative path and changes what differs. A Flux `Kustomization` points at the overlay folder, so one base serves many environments and a fix in the base reaches all of them. `kubectl kustomize` builds any of these folders locally and shows the result.

The Kustomize file changes built objects with transformers. `namespace` sets the namespace, `replicas` sets the replica count of a workload, `images` changes the name, tag or digest of an image, and `labels` adds labels, safely with `includeSelectors: false` on a running workload. The Flux `Kustomization` has matching fields, such as `images`, `namePrefix`, `nameSuffix` and `commonMetadata`, that kustomize-controller applies after the build.

Generators create ConfigMaps and Secrets from literals or files, and add a hash of the content to the name. When the data changes, the name changes, Kustomize rewrites the reference in the Deployment, the Deployment spec changes and Kubernetes rolls the pods. The Flux `Kustomization` prunes the old object because it is no longer in the build. A plain ConfigMap file changes the data only, so the pods keep the old values. A generated Secret is base64, not encrypted.

Components package one change, such as resource limits, in a folder of `kind: Component`. An overlay adds it with `components`, and a Flux `Kustomization` can add it too, with a path relative to `spec.path`. The key facts to remember are these:

- Overlays reuse a base; they never copy it.
- A generator makes the Deployment change whenever the data changes.
- `disableNameSuffixHash: true` removes the rollout.
- A component changes objects; a base adds them.

<!-- astrona:playground:destroy -->
