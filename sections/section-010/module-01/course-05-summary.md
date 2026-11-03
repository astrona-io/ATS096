# Summary

A Flux `Kustomization` is more than a pointer to a folder. It is the overlay that turns one base in Git into the objects of one environment, and two Flux `Kustomization` objects can turn the same base into two different environments.

## What you learned

On every reconciliation, kustomize-controller runs the same steps. It downloads the artifact of the source, builds the folder in `path` with Kustomize, applies its own fields such as `targetNamespace` and `patches`, replaces `${variables}` in the result, and applies everything with server-side apply. If the folder has no Kustomize file `kustomization.yaml`, kustomize-controller generates one that lists every manifest. The Kustomize command-line tool runs only the build step, so `kubectl kustomize` never shows replaced variables. `flux build kustomization` runs all the steps on a local folder, and `flux diff kustomization` compares the result with the cluster and exits with `1` when it finds differences.

`targetNamespace` puts every namespaced object into one namespace, but never creates it. Patches change the built objects. A strategic merge patch is a partial object and merges into the target; a JSON6902 patch is a list of operations on exact paths. Each patch applies only to the objects its `target` selects, and a target that matches nothing changes nothing without any error, so you check the result and not only the `Ready` condition.

Variable substitution sets values per environment. `postBuild.substitute` holds values in the Flux object, and `postBuild.substituteFrom` reads them from ConfigMaps and Secrets in the namespace of the Flux `Kustomization`. `${name:=default}` gives a default, `$${name}` keeps a literal, and the annotation `kustomize.toolkit.fluxcd.io/substitute: disabled` turns substitution off for one object. A missing source stops the reconciliation unless it is marked `optional: true`, which also hides the mistake. The key facts to remember are these:

- One base folder, one Flux `Kustomization` per environment.
- The order is build, overlay, substitution, apply.
- `targetNamespace` needs an existing namespace.
- A wrong patch target and an optional variable source both fail silently.

<!-- astrona:playground:destroy -->
