# Solution: Unblock A Stuck Delivery Pipeline

Work the task yourself first. Running `astrona submit -c sections/section-020/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the two dependencies are still in place and nothing is suspended; every stage is still health-checked against its own Deployment; and all three stages are `Ready`, with `redis` ready and podinfo answering `staging` and `production`.

## Step 1: Read each stage's reason

```sh
flux get kustomizations
kubectl -n flux-system get kustomizations \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].reason}{"\n"}{end}'
```

Each stage reports something different. `infrastructure` fails to build: its message says the path `./infrastructure/cache` was not found. `apps-staging` and `apps-production` report `DependencyNotReady`. Start at the first stage, because the others wait for it.

## Step 2: Fix the infrastructure path

The folder in the repository is `infrastructure/redis`. Run `kubectl -n flux-system edit kustomization infrastructure` and set:

```yaml
  path: ./infrastructure/redis
```

Then reconcile and read the next stage:

```sh
flux reconcile kustomization infrastructure
flux reconcile kustomization apps-staging
flux events --for Kustomization/apps-staging
```

`infrastructure` becomes `Ready`. `apps-staging` now applies podinfo, but after one minute it fails with `HealthCheckFailed`: it waits for the Deployment `podinfo-api`, and the base has no object with that name. podinfo itself runs fine in `podinfo-staging`.

## Step 3: Point the staging health check at the real Deployment

Keep the health check, but check the object the stage really applies. Run `kubectl -n flux-system edit kustomization apps-staging` and change the entry:

```yaml
  healthChecks:
    - apiVersion: apps/v1
      kind: Deployment
      name: podinfo
      namespace: podinfo-staging
```

Replacing the list with `wait: true` is just as correct. Then reconcile:

```sh
flux reconcile kustomization apps-staging
```

`apps-staging` becomes `Ready`.

## Step 4: Fix the production dependency

`apps-production` still reports `DependencyNotReady`, even though staging is ready. Read its message: it waits for `flux-system/apps-stagging`, an object that does not exist. Run `kubectl -n flux-system edit kustomization apps-production` and fix the name:

```yaml
  dependsOn:
    - name: apps-staging
```

Then reconcile and prove the pipeline:

```sh
flux reconcile kustomization apps-production
flux get kustomizations
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

All three stages are `Ready`, and production answers `production`.

## Step 5: Submit

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove `dependsOn` from both stages | Everything becomes `Ready`, and the next bad commit reaches production at once |
| Remove the health check from `apps-staging` | Staging is `Ready` as soon as its objects are stored, so it no longer protects production |
| Create a Deployment called `podinfo-api` | The health check passes on an object nobody uses |
| Create a Flux `Kustomization` called `apps-stagging` | A second, unchecked staging now gates production |

## Common mistakes

- Fixing the later stages first, while `infrastructure` still blocks them.
- Reading `DependencyNotReady` on `apps-production` as a problem with staging, without reading the name in the message.
- Waiting for the next `interval` instead of running `flux reconcile`.
