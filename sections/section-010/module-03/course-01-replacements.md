# Replacements

Sometimes one object holds a value that another object needs. A Service name belongs in the configuration of the Deployment that calls it. A ConfigMap holds the message that a container shows. Writing the value twice means one copy goes stale. Kustomize can copy the value for you while it builds. That feature is called a replacement, and this part shows how it works and how it differs from the variables of a Flux `Kustomization`.

## What a replacement does

A **replacement** is an entry of the field `replacements` in a Kustomize file `kustomization.yaml`. Kustomize reads one value from a **source** object in the build, and writes it into one or more fields of **target** objects in the same build. The copy happens during the build, before kustomize-controller applies anything.

The overlay in the playground repository has one. It is already in `apps/podinfo/overlay/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../base
  - settings.yaml
replacements:
  - source:
      kind: ConfigMap
      name: podinfo-settings
      fieldPath: data.message
    targets:
      - select:
          kind: Deployment
          name: podinfo
        fieldPaths:
          - spec.template.spec.containers.[name=podinfo].env.[name=PODINFO_UI_MESSAGE].value
```

The `source` names the object by `kind` and `name`, and `fieldPath` gives the path of the value, with dots between the keys. The `targets` list says where the value goes. Each target has a `select`, which chooses objects by `kind`, `name`, `namespace` and similar fields, and a list of `fieldPaths`. A path segment in square brackets, such as `[name=podinfo]`, picks the list item whose `name` is `podinfo`, so the path does not depend on the position in the list.

## Build it and read the result

Start the port-forward to Gitea in a second terminal and leave it running. `gitea.localtest.me` resolves to `127.0.0.1`; if your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In your first terminal, clone the repository and build the overlay:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
kubectl kustomize apps/podinfo/overlay
```

The output has the ConfigMap `podinfo-settings` with the message `from-replacement`, and a Deployment whose environment variable `PODINFO_UI_MESSAGE` has the value `from-replacement`. The base file `deployment.yaml` holds the value `placeholder`. Kustomize overwrote it during the build.

Now deploy the overlay. Save this as `kustomization-podinfo-staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/overlay
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-staging.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

The Flux `Kustomization` becomes `Ready` and the request answers `from-replacement`. The Flux object contains no `postBuild` and no patch: the whole logic lives in the Kustomize file in Git.

## Options: create, delimiter and index

A target can carry `options`. Three of them are used most:

| Option | What it does |
| --- | --- |
| `create: true` | Creates the target field when it does not exist yet. Without it, a missing field is an error |
| `delimiter` | Splits the target string at this character, so that only one part of it is replaced |
| `index` | With `delimiter`, the zero-based position of the part to replace |

Try `create`. In your clone, add a second target to the replacement, so that the message is also a label on the Deployment. Edit the `targets` list in `apps/podinfo/overlay/kustomization.yaml` and add this item under the first target:

```yaml
      - select:
          kind: Deployment
          name: podinfo
        fieldPaths:
          - metadata.labels.message
        options:
          create: true
```

Build again with `kubectl kustomize apps/podinfo/overlay`. The Deployment now has the label `message: from-replacement`. The label did not exist in the base, so `create: true` was needed. A `delimiter` works the same way on a value such as `registry.example.com:5000`: with `delimiter: ":"` and `index: 1`, only the port is replaced.

## Replacements and variable substitution

Both features put a value into a field, but they work in different places. A replacement copies a value between objects that are both in the build, and kustomize-controller does not need to know about it. Variable substitution, the `postBuild` field of the Flux `Kustomization`, replaces `${name}` after the build with a value from the Flux object, from a ConfigMap in the cluster or from a Secret in the cluster.

Use a replacement when the value already lives in the repository and must stay in step with another object. Use substitution when the value comes from outside the repository, such as a cluster name, or when different clusters need different values for the same folder. A replacement cannot read the cluster. Substitution cannot read other objects in the build.

You can now copy values inside a build with a replacement and choose between a replacement and a variable. The open question is what to do when a replacement, or any other part of a build, is wrong. The next step is to find out how to see the result before the cluster does.

## Common pitfalls

> [!WARNING]
> - **A source `fieldPath` that does not exist.** The key must match the data exactly: `data.msg` and `data.message` are different keys. The build fails with an error.
> - **Targets that select nothing.** A `select` with a wrong name changes nothing and raises no error. Build the folder and read the result.
> - **Using a list position in a path.** Write `containers.[name=podinfo]`, not a number. A number breaks when the order of the list changes.
> - **Expecting a replacement to read the cluster.** The source must be an object in the build, not a live object.
