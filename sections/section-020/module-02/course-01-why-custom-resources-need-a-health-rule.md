# Why Custom Resources Need A Health Rule

A platform team defines a custom resource called `Widget`. Its controller starts the widget and writes the field `status.phase` with the value `Starting` and later `Running`. Flux applies the `Widget` objects from Git, but it has never heard of this kind. This part shows what Flux concludes about such an object, and why that conclusion is wrong.

## How kustomize-controller reads health

A health check is the step after the apply in which kustomize-controller waits until the applied objects are healthy. kustomize-controller uses the library kstatus for this. kstatus knows the built-in kinds: a Deployment is healthy when its rollout finished, a Job when it completed, a Pod when it is ready. For a custom resource it looks for the standard `Ready` condition in `status.conditions`. If the object has no status at all, kstatus calls it healthy, because nothing says it is not.

The consequence is a quiet one. A custom resource whose controller does not write a `Ready` condition, or has not written it yet, passes the health check the moment the API server stores it.

## Create the custom resource definition

A custom resource definition (CRD) teaches the API server a new kind. Save this as `crd-widget.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: widgets.demo.astrona.io
spec:
  group: demo.astrona.io
  scope: Namespaced
  names:
    kind: Widget
    plural: widgets
    singular: widget
  versions:
    - name: v1
      served: true
      storage: true
      subresources:
        status: {}
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                size:
                  type: integer
            status:
              type: object
              properties:
                phase:
                  type: string
```

Apply it:

```sh
kubectl apply -f crd-widget.yaml
```

The definition has a `status` subresource, which means the field `status` can be written on its own, the way a controller writes it. No controller runs in this playground, so you play that role later with `kubectl`.

## Put a Widget in Git

Start the port-forward in a second terminal, then clone the repository and add a folder for the widget:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
mkdir -p apps/widget
```

Save this as `apps/widget/widget.yaml`:

```yaml
apiVersion: demo.astrona.io/v1
kind: Widget
metadata:
  name: gauge
spec:
  size: 1
```

Save this as `apps/widget/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - widget.yaml
```

Commit and push the folder:

```sh
git add apps/widget
git commit -m "Add the widget"
git push origin main
```

## Apply it without a rule

Save this as `kustomization-widgets.yaml`, outside the clone:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: widgets
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/widget
  prune: true
  wait: true
  timeout: 1m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it and look at the result:

```sh
kubectl apply -f kustomization-widgets.yaml
flux get kustomizations
kubectl -n podinfo-staging get widget gauge -o jsonpath='{.status}'
```

`widgets` is `Ready` within seconds, with `wait: true` on. The last command prints nothing, because the object has no status. The Flux `Kustomization` called a widget healthy that has not started. A dependent stage would now go ahead against a widget that does nothing.

You now know that Flux judges a custom resource only by its `Ready` condition and calls it healthy when it has none. The open question is how to give Flux your own rule for the kind.

## Common pitfalls

> [!WARNING]
> - **Assuming `wait: true` proves a custom resource works.** It proves only that the API server stored it, unless the object reports a `Ready` condition.
> - **Applying an object before its definition exists.** The apply fails because the API server does not know the kind. Apply the definition first, or order the two stages.
> - **Writing the status in the object file.** The API server ignores `status` in a normal apply when the definition has a `status` subresource.
