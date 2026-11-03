# Summary

A `HelmRelease` builds one values document from several sources. The order is: the defaults of the chart, then `valuesFiles` for a chart from Git, then each `valuesFrom` entry in list order, and last `spec.values`, which always wins. Maps merge key by key, and a list is replaced as a whole.

`valuesFrom` reads a ConfigMap or a Secret from the namespace of the release. By default it parses the key `values.yaml` as a values document. With `valuesKey` and `targetPath` it sets one string at one path instead. `optional: true` lets the release install without a missing object, and should never hide a typo. The values are read at each reconciliation.

A post-renderer changes the rendered YAML before it is installed. `spec.postRenderers` takes a `kustomize` block with `patches`, selected by target, and `images`, which rewrite image names and tags. Use it when no chart value reaches the setting, and keep each patch small.

`spec.test.enable` makes helm-controller run the tests of the chart after an install or an upgrade. Helm stores each revision in a Secret named `sh.helm.release.v1.<release>.v<revision>`. Decoding the key `release` with `base64 -d`, `base64 -d` and `gunzip` gives JSON with the merged `config` and the installed `manifest`.

- Know the order of the sources; `spec.values` wins.
- A post-renderer hides a difference; prefer a chart value.
- Check the `manifest` in Helm's storage to see what was really installed.

<!-- astrona:playground:destroy -->
