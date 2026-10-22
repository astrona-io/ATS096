# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** ordering and gating

## Scenario

The repository `gitops/fleet` holds a `redis` cache in `infrastructure/redis` and the `podinfo` base in `apps/podinfo/base`; podinfo uses the cache. Last month a broken commit reached production in the same minute as staging. The team wants a pipeline in which nothing reaches production unless it runs in staging first. The `GitRepository` `fleet` in `flux-system` is `Ready`, and the namespaces `podinfo-staging` and `podinfo-production` exist.

## Your task

Create three Flux `Kustomization` objects in `flux-system`, all using the source `fleet` and pruning:

1. **`infrastructure`** applies `./infrastructure/redis`.
2. **`apps-staging`** applies `./apps/podinfo/base` into `podinfo-staging`, with the label `environment: staging` and the message **`staging`**. It waits for `infrastructure`.
3. **`apps-production`** applies `./apps/podinfo/base` into `podinfo-production`, with the label `environment: production` and the message **`production`**. It waits for `apps-staging`.

Every stage must be health-checked, so that `Ready` means its Deployment runs.

## Constraints

- Do not change the repository, and do not apply the manifests yourself.
- Use `dependsOn` for the order. Do not rely on the order in which you create the objects.
- Health-check every stage, with `wait: true` or with a health check on the stage's own Deployment.

## Done when

- `flux get kustomizations` shows all three stages `Ready`.
- `apps-staging` depends on `infrastructure`, and `apps-production` depends on `apps-staging`.
- The `redis` Deployment in `infrastructure` is ready, and podinfo answers `staging` in `podinfo-staging` and `production` in `podinfo-production`.
