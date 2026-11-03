# Components

Overlays remove most copying, but not all of it. Suppose three overlays should all get the same resource limits, or the same sidecar, or the same set of labels. Each overlay would hold the same patch, and the copies would drift apart again. A Kustomize component packages one such change in its own folder, and an overlay adds it with one line. This part builds a component, adds it in the Kustomize file, and then adds it from the Flux `Kustomization`.

## What a component is

A **component** is a folder with a Kustomize file whose `kind` is `Component` and whose `apiVersion` is `kustomize.config.k8s.io/v1alpha1`. It can hold patches, transformers and generators, like a Kustomize file can, but it has no `resources` of its own that make up an application. It does not build on its own. It only makes sense inside an overlay, where it changes the objects that the overlay already has.

The difference from a base shows in how the folder is used. An overlay lists a base under `resources`, which adds objects. An overlay lists a component under `components`, which changes objects. The playground repository has one component:

```yaml
apiVersion: kustomize.config.k8s.io/v1alpha1
kind: Component
patches:
  - target:
      kind: Deployment
      name: podinfo
    patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: podinfo
      spec:
        template:
          spec:
            containers:
              - name: podinfo
                resources:
                  limits:
                    cpu: 200m
                    memory: 128Mi
```

The patch is a strategic merge patch. It matches the container by `name`, so it adds `limits` and keeps the `requests` from the base. This file is already in `apps/podinfo/components/resource-limits`.

## Add the component in the Kustomize file

Open `apps/podinfo/overlays/production/kustomization.yaml` in your clone and add the `components` field. The path is relative to the folder of this Kustomize file:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo-production
resources:
  - ../../base
  - configmap.yaml
components:
  - ../../components/resource-limits
replicas:
  - name: podinfo
    count: 2
```

Build it, and look at the container of the Deployment:

```sh
kubectl kustomize apps/podinfo/overlays/production
```

The built Deployment has `requests` of `10m` CPU and `32Mi` memory from the base, and `limits` of `200m` CPU and `128Mi` memory from the component. Run the same build on the staging overlay. It has no `limits`, because staging does not list the component. One folder in Git now gives limits to exactly the overlays that ask for them.

Commit and push the change. The Flux `Kustomization` `podinfo-production` must exist: if you have not created it yet, save a copy of the staging file with the name `podinfo-production` and the path `./apps/podinfo/overlays/production`, and apply it. Then let Flux apply the new commit:

```sh
git add apps/podinfo/overlays/production/kustomization.yaml
git commit -m "Add resource limits to production"
git push origin main
flux reconcile source git fleet
flux reconcile kustomization podinfo-production
```

Then check the result:

```sh
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].resources}'
```

The command prints both the `limits` and the `requests`. The Deployment spec changed, so Kubernetes rolled out new pods with the limits.

## Add a component from the Flux Kustomization

The Flux `Kustomization` has a field `components` as well. It takes a list of paths to components, relative to `spec.path`. kustomize-controller adds them to the build of the folder in `path`, so the Kustomize file in Git does not have to list them. This is useful when one cluster needs a component and another does not, and both use the same overlay folder.

The shape of the field is the same list of relative paths:

```yaml
spec:
  path: ./apps/podinfo/overlays/staging
  components:
    - ../../components/resource-limits
```

The path `../../components/resource-limits` is relative to `./apps/podinfo/overlays/staging`, which is the same distance as in the Kustomize file. Because the path stays inside the same source, the component is part of the artifact kustomize-controller downloaded.

Which place is better? A component listed in the Kustomize file is part of what the overlay is, and it travels with the overlay wherever it is used. A component listed in the Flux `Kustomization` is part of how one cluster uses the overlay. Prefer the first for anything every user of the overlay must have, and the second for exceptions.

## Order and limits of components

Kustomize applies the entries of `components` in the order of the list, and applies them after the resources are loaded. Two components that patch the same field apply in list order, so the later one wins. A component can also list other components under its own `components`.

A component cannot create the base it patches. If the object it patches is missing from the build, the patch selects nothing and the build still succeeds, as with any patch with a target that matches nothing. Check the built result, not only that the build worked.

You now know how to package one change as a component and use it from the Kustomize file or from the Flux `Kustomization`. You have also followed the path from the base to the cluster: the base holds the common objects, the overlay shapes them for one environment, generators make configuration that rolls pods, and components share a change between overlays.

## Common pitfalls

> [!WARNING]
> - **Listing a component under `resources`.** A component is not a base. Kustomize refuses to build it as a resource. Use `components`.
> - **A wrong relative path.** In the Kustomize file the path is relative to the folder of that file. In the Flux `Kustomization` it is relative to `spec.path`.
> - **A patch in the component that matches no object.** The build succeeds and nothing changes. Build the overlay and read the result.
> - **Using a component to add a whole new application.** Components change what is there. New objects belong in a base listed under `resources`.
