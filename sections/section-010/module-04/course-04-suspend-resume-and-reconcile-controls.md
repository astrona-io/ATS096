# Suspend, Resume And Reconcile Controls

Flux keeps the cluster equal to Git. Sometimes you need it to stop: during an incident, while you test a manual change, or before a risky migration. Deleting the Flux `Kustomization` is the wrong tool, because with `prune: true` the deletion can remove everything it applied. Flux has controls that pause and restart reconciliation without removing anything. This part uses them on a small application.

## The controls

| Control | Scope | Effect |
| --- | --- | --- |
| `flux suspend kustomization NAME` | One Flux `Kustomization` | Sets `spec.suspend: true`. No reconcile runs, so Git changes are not applied and drift is not corrected |
| `flux resume kustomization NAME` | One Flux `Kustomization` | Sets `spec.suspend: false` and reconciles at once |
| `flux suspend source git NAME` | One source | The source stops fetching, so new commits never reach the Flux `Kustomization` objects that use it |
| `flux reconcile kustomization NAME --with-source` | One Flux `Kustomization` | Refreshes the source first, then reconciles |
| Annotation `kustomize.toolkit.fluxcd.io/reconcile: disabled` | One live object | Flux skips that object while the annotation is there |
| Annotation `kustomize.toolkit.fluxcd.io/prune: disabled` | One object in the manifests | Flux does not delete the object when it leaves the build |

The first rows pause a whole Flux `Kustomization`. The last two work on one object, which is often what you want.

## Prepare an application

Save these two files in your clone of the repository, in a new folder `apps/podinfo-controls`. The first is the Kustomize file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
```

The second is `deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo-controls
  labels:
    app: podinfo-controls
spec:
  replicas: 1
  selector:
    matchLabels:
      app: podinfo-controls
  template:
    metadata:
      labels:
        app: podinfo-controls
    spec:
      containers:
        - name: podinfo
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          env:
            - name: PODINFO_UI_MESSAGE
              value: before
          ports:
            - name: http
              containerPort: 9898
```

<!-- astrona:playground:renew -->

Commit and push the folder:

```sh
git add apps/podinfo-controls
git commit -m "Add the podinfo-controls folder"
git push origin main
```

Save this as `podinfo-controls.yaml` and apply it:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-controls
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo-controls
  prune: true
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
```

```sh
kubectl apply -f podinfo-controls.yaml
flux reconcile kustomization podinfo-controls --with-source
kubectl -n podinfo-staging rollout status deployment/podinfo-controls
```

This folder has no Service, so read the message through the pod address. Repeat these two lines whenever you want to read the message again, because a new pod has a new address:

```sh
POD_IP=$(kubectl -n podinfo-staging get pod -l app=podinfo-controls -o jsonpath='{.items[0].status.podIP}')
kubectl -n gitea exec deploy/tester -- sh -c "curl -s http://$POD_IP:9898 | jq -r .message"
```

The message is `before`.

## Suspend and change Git

Suspend the Flux `Kustomization`:

```sh
flux suspend kustomization podinfo-controls
flux get kustomizations
```

The column `SUSPENDED` shows `True` for `podinfo-controls`. Now change `value: before` to `value: after` in `apps/podinfo-controls/deployment.yaml`, commit, push, and refresh the source:

```sh
git add apps/podinfo-controls/deployment.yaml
git commit -m "Change the message to after"
git push origin main
flux reconcile source git fleet
flux get kustomizations
```

The source has the new commit, but the Flux `Kustomization` stays suspended and applies nothing. The pod still answers `before`; read it again with the two lines from earlier. Also make a manual change while it is suspended:

```sh
kubectl -n podinfo-staging scale deployment podinfo-controls --replicas=3
kubectl -n podinfo-staging get deployment podinfo-controls
```

The Deployment has 3 replicas, and nothing sets it back.

## Resume

```sh
flux resume kustomization podinfo-controls
flux get kustomizations
kubectl -n podinfo-staging get deployment podinfo-controls
```

The resume applies the commit at once. The message changes to `after`, a rollout replaces the pod, and the replica count returns to 1, because the manifests in Git set it and the apply corrects the difference.

## Pause one object

A manual test sometimes needs only one object to stay as it is. Put the annotation on the live Deployment and scale it:

```sh
kubectl -n podinfo-staging annotate deployment podinfo-controls kustomize.toolkit.fluxcd.io/reconcile=disabled
kubectl -n podinfo-staging scale deployment podinfo-controls --replicas=2
flux reconcile kustomization podinfo-controls
kubectl -n podinfo-staging get deployment podinfo-controls
```

The Flux `Kustomization` reconciles and reports `Ready`, but it skips the annotated Deployment, so it keeps 2 replicas. Remove the annotation to hand control back. The trailing dash removes an annotation:

```sh
kubectl -n podinfo-staging annotate deployment podinfo-controls kustomize.toolkit.fluxcd.io/reconcile-
flux reconcile kustomization podinfo-controls
kubectl -n podinfo-staging get deployment podinfo-controls
```

The replica count is back to 1.

The annotation `kustomize.toolkit.fluxcd.io/prune: disabled` is different. You put it in the manifest in Git, and then the object stays in the cluster when you later remove it from the folder. Use it for objects that must outlive their Flux `Kustomization`, such as a PersistentVolumeClaim.

## Timing fields

Three fields shape how often and how long a Flux `Kustomization` works. `interval` is the time between regular reconciles. `retryInterval` is the time between attempts after a failure; if you leave it out, the failed object retries at the `interval`. `timeout` limits one apply or one health wait. A short `retryInterval` such as `1m` on a Flux `Kustomization` with a long `interval` gets a failed apply fixed soon after the cause is repaired.

## Common pitfalls

> [!WARNING]
> - **Leaving a Flux `Kustomization` suspended.** The cluster drifts from Git and nobody sees it. Check the `SUSPENDED` column during every review.
> - **Deleting the Flux `Kustomization` to stop it.** With `prune: true` the objects it applied are removed. Suspend it instead.
> - **Suspending the Flux `Kustomization` and expecting the source to stop.** Other Flux `Kustomization` objects that use the same source keep reconciling.
> - **Forgetting the reconcile annotation on a live object.** The object stays out of Flux until you remove the annotation, even after the incident ends.
> - **Expecting `flux reconcile kustomization` to apply a suspended object.** Resume it first.
