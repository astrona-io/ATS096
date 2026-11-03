# Solution: Roll Pods With A Generated ConfigMap

Work the task yourself first. Running `astrona submit -c sections/section-010/module-02/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `podinfo-staging` still builds the staging overlay and is `Ready`; the Deployment reads a generated ConfigMap named `podinfo-config-<hash>` that Flux applied, with no other `podinfo-config*` ConfigMap left; and podinfo answers with the message `rolled-out`.

## Step 1: Clone the repository

Start the port-forward to Gitea in a second terminal first (`kubectl -n gitea port-forward svc/gitea-http 3000:3000`). Then clone the repository and look at the overlay:

```sh
flux get kustomizations
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
cat apps/podinfo/overlays/staging/kustomization.yaml
```

The Flux `Kustomization` is `Ready`. The overlay lists `../../base` and `configmap.yaml` under `resources`. The ConfigMap in `configmap.yaml` has a fixed name, `podinfo-config`, so a change of its data changes no name and the Deployment spec stays identical.

## Step 2: Replace the file with a generator

Open `apps/podinfo/overlays/staging/kustomization.yaml` and replace its content with this:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo-staging
resources:
  - ../../base
configMapGenerator:
  - name: podinfo-config
    literals:
      - PODINFO_UI_MESSAGE=rolled-out
```

You can check the build before you commit it. The output has a ConfigMap whose name ends in a hash, and the Deployment refers to that same name:

```sh
kubectl kustomize apps/podinfo/overlays/staging
```

## Step 3: Commit, push and reconcile

```sh
git add apps/podinfo/overlays/staging/kustomization.yaml
git commit -m "Generate the podinfo ConfigMap"
git push origin main
flux reconcile source git fleet
flux reconcile kustomization podinfo-staging
```

kustomize-controller applies the new ConfigMap, applies the Deployment with the new ConfigMap name, and then prunes the old ConfigMap `podinfo-config`, which is no longer in the build.

## Step 4: Prove the rollout

```sh
flux get kustomizations
kubectl -n podinfo-staging get configmap
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}'
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

`podinfo-staging` is `Ready`. One ConfigMap is left, named `podinfo-config-` and a hash. The Deployment refers to that name, and the request answers `rolled-out`. If it still shows `staging`, the new pod is still starting; run the request again after a few seconds.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-02/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Edit the message in `configmap.yaml` | Flux updates the ConfigMap, but the Deployment spec is the same, so the pod keeps the old message |
| `kubectl rollout restart deployment/podinfo` | The pod restarts once, but the next message change needs another restart, and the grader finds the fixed ConfigMap name |
| `disableNameSuffixHash: true` in the generator options | The name stays `podinfo-config`, so nothing rolls the pods |
| Keep both the file and the generator | Two ConfigMaps are applied and the grader finds a plain `podinfo-config` left over |

## Common mistakes

- Forgetting to remove `configmap.yaml` from `resources`, so the build has the plain ConfigMap and the generated one.
- Writing `PODINFO_UI_MESSAGE: rolled-out` under `literals` with a colon. A literal is `KEY=value`.
- Checking the message before the new pod is ready.

## Practice on your own

- Change the message to a third value and watch the hash in the ConfigMap name change.
- Add the `behavior: replace` option with a generator in an overlay of a base that already generates the ConfigMap.
- Run `flux diff kustomization podinfo-staging --path ./apps/podinfo/overlays/staging` from your clone before you push, and read what it reports.
