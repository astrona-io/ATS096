# Bases And Overlays

An application usually runs in more than one environment, and the environments differ in a few values only. Copying the whole folder for each environment fixes that for a week. This part shows the Kustomize answer: one base folder that holds the common objects, and one overlay folder per environment that reuses the base and changes what differs. Then it points a Flux `Kustomization` at each overlay.

## A base and an overlay

A **base** is a folder with a Kustomize file `kustomization.yaml` that lists plain Kubernetes manifests under `resources`. It builds and deploys on its own. An **overlay** is another folder whose Kustomize file lists the base as a resource and adds changes on top. The overlay does not copy the base. It points at it with a relative path.

The playground repository has this layout:

```text
apps/podinfo/
├── base/                  deployment.yaml, service.yaml, kustomization.yaml
└── overlays/
    ├── staging/           kustomization.yaml, configmap.yaml
    └── production/        kustomization.yaml, configmap.yaml
```

The overlay for production lists the base and its own ConfigMap, sets a namespace and sets the replica count. The following Kustomize file is already in the repository. You do not apply it:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo-production
resources:
  - ../../base
  - configmap.yaml
replicas:
  - name: podinfo
    count: 2
```

The field `resources` takes files and folders. A folder must hold its own Kustomize file, and Kustomize builds it first. The field `namespace` sets the namespace of every namespaced object in the build, and it also updates references to those objects. The field `replicas` sets the replica count of the workload with that name, so the overlay needs no patch for it.

## Build an overlay with Kustomize

Start the port-forward to Gitea in a second terminal and leave it running. `gitea.localtest.me` resolves to `127.0.0.1`; if your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In your first terminal, clone the repository and build the production overlay, the way you would without Flux:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
kubectl kustomize apps/podinfo/overlays/production
```

`kubectl kustomize` runs the Kustomize build and prints the result. You see the ConfigMap `podinfo-config` with the message `production`, the Deployment `podinfo` with `replicas: 2`, and the Service, all with `namespace: podinfo-production`. Run it again on `apps/podinfo/overlays/staging`: the namespace is `podinfo-staging` and the replica count is `1`, because the base value stays when the overlay sets none.

Notice what the build did to the Deployment. Its `envFrom` still names `podinfo-config`, and the ConfigMap in the output has that name. They match because the overlay supplied the ConfigMap that the base expects.

## Point a Flux Kustomization at an overlay

The Flux `Kustomization` needs only the path of the overlay. It needs no `targetNamespace` and no patches, because the overlay already carries them.

Save this as `kustomization-podinfo-staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/overlays/staging
  prune: true
  wait: true
  timeout: 2m
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
kubectl -n podinfo-staging get deployment,configmap,service
```

The Flux `Kustomization` becomes `Ready`. The namespace `podinfo-staging` now holds the Deployment, the Service and the ConfigMap `podinfo-config`. Do the same for production: save a second file `kustomization-podinfo-production.yaml` that differs only in `name` and in `path: ./apps/podinfo/overlays/production`, and apply it. The namespace `podinfo-production` then holds a Deployment with 2 replicas.

## Why overlays differ from copies

Both environments now come from one base. A fix in `base/deployment.yaml`, for example a new probe, reaches staging and production on the next reconciliation of each Flux `Kustomization`. The overlay folders hold only what differs, which is a namespace, a replica count and a message. When a reviewer reads a pull request for `overlays/production`, every changed line is a production decision.

You can also build an overlay with Flux instead of Kustomize. The command `flux build kustomization podinfo-staging --path ./apps/podinfo/overlays/staging`, run from the clone, builds the folder the way kustomize-controller does and compares nothing with the cluster. For this overlay the result is the same as `kubectl kustomize`, because the Flux object adds no fields of its own.

You can now split an application into a base and overlays and apply each overlay with its own Flux `Kustomization`. The next question is how an overlay changes things that are not a namespace or a replica count, such as an image tag or a label on every object. The Kustomize file has transformer fields for that.

## Common pitfalls

> [!WARNING]
> - **A base path that does not resolve.** `../../base` is relative to the folder of the Kustomize file, not to the repository root. A wrong number of `..` fails the build.
> - **A folder in `resources` without its own Kustomize file.** Kustomize treats it as a base and needs a `kustomization.yaml` there. Files are listed one by one.
> - **Setting `namespace` in the overlay and `targetNamespace` in the Flux `Kustomization` to different values.** `targetNamespace` overrides the namespace of the overlay, so the overlay value is silently ignored.
> - **Pointing the Flux `Kustomization` at the base instead of the overlay.** The base builds, but the ConfigMap that the Deployment needs is missing and the pod stays in `CreateContainerConfigError`.
