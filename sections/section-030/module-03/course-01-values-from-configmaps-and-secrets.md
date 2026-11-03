# Values From ConfigMaps And Secrets

Values written into a `HelmRelease` are public to everyone who reads the repository. Some values should not be: a password, or a setting that an operator changes without a commit. Flux lets a release read values from a ConfigMap or a Secret in its own namespace. This part installs podinfo with its message taken from a ConfigMap, and then reads a single value into one place of the values document.

## The field valuesFrom

`spec.valuesFrom` is a list. Each entry names an object by `kind` (`ConfigMap` or `Secret`) and `name`, and the object must be in the namespace of the release. By default Flux reads the key `values.yaml` of the object and treats its content as a YAML values document.

Create the repository and the values first. Save this as `helmrepository-podinfo.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: podinfo-staging
spec:
  interval: 10m
  url: https://stefanprodan.github.io/podinfo
```

Save this as `values-configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-values
  namespace: podinfo-staging
data:
  values.yaml: |
    ui:
      message: from the ConfigMap
```

Save this as `helmrelease-podinfo.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo-staging
spec:
  interval: 10m
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
```

Apply all three and wait:

```sh
kubectl apply -f helmrepository-podinfo.yaml -f values-configmap.yaml -f helmrelease-podinfo.yaml
flux reconcile helmrelease podinfo -n podinfo-staging --with-source
flux get helmreleases -n podinfo-staging
kubectl -n gitea exec deploy/tester -- sh -c "curl -s http://podinfo.podinfo-staging:9898 | jq -r .message"
```

The answer is the message from the ConfigMap. If the ConfigMap changes later, the release does not notice by itself at once: helm-controller reads the values on each reconciliation, so the change arrives at the next interval, or when you run `flux reconcile helmrelease`.

## One value into one place

A whole document is not always what you have. A Secret often holds a single string, for example a token. `valuesKey` picks the key to read, and `targetPath` says where in the values document the content goes:

```yaml
  valuesFrom:
    - kind: Secret
      name: podinfo-token
      valuesKey: token
      targetPath: ui.message
```

With `targetPath`, the content of the key is not parsed as YAML. It is set as the value at that path, here `ui.message`. Use it for a plain string. It works for a ConfigMap in the same way.

## Objects that may not exist

If a listed object or key does not exist, the release fails with a message that names it. Setting `optional: true` on the entry turns that into a skip: the release installs without those values. Use it for values that are really optional, never to hide a mistake in a name.

You can now bring values from the cluster into a release and put a single string at one path. The next question is which value wins when the same key is set in more than one place.

## Common pitfalls

> [!WARNING]
> - **An object in another namespace.** `valuesFrom` reads only from the namespace of the release.
> - **Expecting an instant change.** Values are read at reconciliation, not on a ConfigMap update.
> - **Using `targetPath` for a YAML document.** It sets a string, it does not parse.
> - **`optional: true` on a typo.** The release installs with the default and nobody notices.
