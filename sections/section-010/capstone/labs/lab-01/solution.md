# Solution: Repair The Overlays Of Two Environments

Work the task yourself first. Running `astrona submit -c sections/section-010/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: staging is `Ready`, applies into `podinfo-staging` and answers `staging`; production is `Ready`, reads its variables from `podinfo-prod-vars` without `optional: true`, and answers `production from ConfigMap`; and the production Deployment runs 3 ready replicas.

## Step 1: Read the state of both objects

```sh
flux get kustomizations
flux events --for Kustomization/podinfo-staging
flux events --for Kustomization/podinfo-production
```

Both objects are not ready, for different reasons. The staging events say the apply failed because the namespace `podinfo-stage` was not found. The production events say kustomize-controller could not find the ConfigMap `podinfo-production-vars`. These are two separate faults; fix them one at a time.

## Step 2: Fix the staging namespace

`targetNamespace` never creates a namespace, and the namespace for staging is `podinfo-staging`. Run `kubectl -n flux-system edit kustomization podinfo-staging` and change the field to:

```yaml
  targetNamespace: podinfo-staging
```

Then check the result:

```sh
flux reconcile kustomization podinfo-staging
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

Staging becomes `Ready` and answers `staging`. Creating a namespace called `podinfo-stage` would also make it ready, but in the wrong place; the grader looks in `podinfo-staging`.

## Step 3: Point production at the real ConfigMap

List the ConfigMaps in `flux-system` to see what exists:

```sh
kubectl -n flux-system get configmap
```

The values live in `podinfo-prod-vars`. Run `kubectl -n flux-system edit kustomization podinfo-production` and change the reference:

```yaml
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: podinfo-prod-vars
```

Then reconcile:

```sh
flux reconcile kustomization podinfo-production
```

Production becomes `Ready` and answers `production from ConfigMap`. Setting `optional: true` would also have made it ready, but with the default message `deployed by Flux`, which is why the task forbids it.

## Step 4: Find the patch that changes nothing

Production is `Ready` now, so check the result, not only the condition:

```sh
kubectl -n podinfo-production get deployment podinfo
```

The Deployment runs 1 replica, not 3. The patch in the Flux object targets `name: podinfo-api`, and the build has no object with that name, so the patch selects nothing and nobody gets an error. Run `kubectl -n flux-system edit kustomization podinfo-production` once more and fix the target:

```yaml
      target:
        kind: Deployment
        name: podinfo
```

Then check the result:

```sh
flux reconcile kustomization podinfo-production
kubectl -n podinfo-production get deployment podinfo
```

The Deployment now runs 3 ready replicas.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the namespace `podinfo-stage` | Staging is ready, in a namespace nobody uses |
| Create a ConfigMap `podinfo-production-vars` | Two sources of the same values now exist, and they will drift apart |
| Set `optional: true` | Production is ready with the default message and the label `dev` |
| `kubectl scale --replicas=3` | Flux puts it back to the built value at the next reconciliation |

## Common mistakes

- Stopping when both objects are `Ready`. The patch fault never shows up as an error; only the replica count reveals it.
- Editing the ConfigMap instead of the reference to it.
- Reading the message before the new pods are ready.
