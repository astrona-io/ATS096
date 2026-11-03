# Solution

## Step 1: Write the release

`valuesFrom` takes the string from the ConfigMap into the path `message`. The post-renderer patch targets the rendered ConfigMap by kind and name, and adds the annotation.

Save this as `helmrelease-hello.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: hello
  namespace: podinfo-staging
spec:
  interval: 10m
  chart:
    spec:
      chart: ./charts/hello
      reconcileStrategy: Revision
      sourceRef:
        kind: GitRepository
        name: fleet
        namespace: flux-system
  valuesFrom:
    - kind: ConfigMap
      name: hello-message
      valuesKey: message
      targetPath: message
  postRenderers:
    - kustomize:
        patches:
          - target:
              kind: ConfigMap
              name: hello-config
            patch: |
              apiVersion: v1
              kind: ConfigMap
              metadata:
                name: hello-config
                annotations:
                  owner: platform
```

```sh
kubectl apply -f helmrelease-hello.yaml
astrona submit
```

The first check should pass; the second can still fail while the release installs.

## Step 2: Wait for the install and check

```sh
flux reconcile helmrelease hello -n podinfo-staging --with-source
flux get helmreleases -n podinfo-staging
kubectl -n podinfo-staging get configmap hello-config -o jsonpath='{.data.message} {.metadata.annotations.owner}{"\n"}'
astrona submit
```

The output is `from-configmap platform`. If the annotation is missing, compare the `kind` and `name` of the patch target with the rendered ConfigMap.
