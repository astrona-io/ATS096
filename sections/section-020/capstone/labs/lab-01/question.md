# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** ordering and gating

## Scenario

The delivery pipeline for `podinfo` has three stages in `flux-system`: `infrastructure` (the `redis` cache), `apps-staging` and `apps-production`. It has not delivered anything for a day. Someone in the team suggested "just removing the `dependsOn` and the health checks so things move again". The release manager said no: the pipeline must keep its order and its gates, and still deliver.

## Your task

Make all three stages `Ready`, so that:

1. `redis` runs in the namespace `infrastructure`, from the folder `./infrastructure/redis`.
2. podinfo in `podinfo-staging` answers with the message **`staging`**.
3. podinfo in `podinfo-production` answers with the message **`production`**.

## Constraints

- Do not change the repository, and do not apply the manifests yourself.
- Keep the order: `apps-staging` depends on `infrastructure`, and `apps-production` depends on `apps-staging`.
- Keep every stage health-checked against the Deployment it applies (`wait: true`, or a `healthChecks` entry for that Deployment).
- Do not suspend any stage, and do not delete and recreate them.

## Done when

- `flux get kustomizations` shows all three stages `Ready`.
- The `redis` Deployment is ready, and podinfo answers `staging` and `production` in the two namespaces.
