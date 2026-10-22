# Solution: Build A Staged Pipeline From Staging To Production

Work the task yourself first. Running `astrona submit -c sections/section-020/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the two dependencies exist; every stage is health-checked (`wait: true`, or a `healthChecks` entry for its own Deployment); and all three stages are `Ready`, with `redis` ready and podinfo answering `staging` and `production`.

## Step 1: Create the infrastructure stage

Save this as `kustomization-infrastructure.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: infrastructure
  namespace: flux-system
spec:
  interval: 10m
  path: ./infrastructure/redis
  prune: true
  wait: true
  timeout: 2m
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it:

```sh
kubectl apply -f kustomization-infrastructure.yaml
```

`wait: true` matters here: it makes `Ready` mean that `redis` runs, which is what the next stage waits for. The folder brings its own namespace, so the object needs no `targetNamespace`.

## Step 2: Create the staging stage

Save this as `kustomization-apps-staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps-staging
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 30s
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  dependsOn:
    - name: infrastructure
  sourceRef:
    kind: GitRepository
    name: fleet
  postBuild:
    substitute:
      environment: staging
      message: staging
```

Apply it:

```sh
kubectl apply -f kustomization-apps-staging.yaml
```

## Step 3: Create the production stage

Save this as `kustomization-apps-production.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps-production
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 30s
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-production
  dependsOn:
    - name: apps-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  postBuild:
    substitute:
      environment: production
      message: production
```

Apply it:

```sh
kubectl apply -f kustomization-apps-production.yaml
```

## Step 4: Watch the pipeline and prove it

```sh
flux get kustomizations --watch
```

The stages become `Ready` in order: `infrastructure` first, then `apps-staging`, then `apps-production`. Stop the watch with Ctrl-C, then check the workloads:

```sh
kubectl -n infrastructure get deployment redis
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

`redis` is ready, and podinfo answers `staging` and `production`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Leave out `dependsOn` and create the objects in order | Flux ignores creation order; the next commit reaches all stages at once |
| `dependsOn` without `wait` or `healthChecks` | Each stage is `Ready` when its objects are stored, so a broken staging does not stop production |
| One Flux `Kustomization` for both environments | There is no stage between them to stop a bad commit |

## Common mistakes

- A typo in a dependency name, which waits forever with `DependencyNotReady`.
- `targetNamespace` on `infrastructure`, which moves `redis` out of the namespace `infrastructure`, so podinfo can no longer reach it at `redis.infrastructure`.
- No `retryInterval`, so a waiting stage notices its dependency only after a whole `interval`.

## Practice on your own

- Push a commit that breaks the podinfo image tag, and confirm that production keeps the old version.
- Replace `wait: true` on `apps-production` with a `healthChecks` entry for its Deployment.
- Break `redis` in Git and predict which stages stop.
