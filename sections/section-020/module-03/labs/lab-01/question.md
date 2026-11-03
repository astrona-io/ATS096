# Question

Solve this question on: `terminal`

**Time:** about 15 minutes · **Topic:** the reconciliation lifecycle

## Scenario

During an incident an operator suspended the Flux `Kustomization` `apps-staging` in `flux-system`, which applies `./apps/podinfo/base` into `podinfo-staging`. The incident is over, but nobody resumed the stage. The operator also left an `interval` of `24h` and a `timeout` of `5s`, which is shorter than a normal rollout. The `GitRepository` `fleet` is `Ready`.

## Your task

Bring `apps-staging` back to a working state:

1. Resume it.
2. Set `interval` to `5m`, `retryInterval` to `1m` and `timeout` to `3m`.
3. Request a reconciliation by hand, and make sure the source is fetched first.

## Constraints

- Do not delete and recreate the Flux `Kustomization`.
- Do not apply the application's manifests yourself with `kubectl`.

## Done when

- `flux get kustomizations` shows `apps-staging` not suspended and `Ready`.
- The object has the three timer values above.
- The status shows a handled manual reconciliation, and `http://podinfo.podinfo-staging:9898` answers with the message `staging`.
