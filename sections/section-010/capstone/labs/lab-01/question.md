# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** building and shaping what Flux applies

## Scenario

Two Flux `Kustomization` objects in `flux-system` deploy the base `apps/podinfo/base` to staging and production. They were written in a hurry, and the release manager reports three things: staging never appeared, production does not deploy, and the production replica count "was set to 3 last week, but nobody has seen 3 pods". The platform team stored the production values in the ConfigMap `podinfo-prod-vars` in `flux-system`.

## Your task

Fix the two Flux `Kustomization` objects `podinfo-staging` and `podinfo-production` so that:

1. **Staging** runs in the namespace `podinfo-staging`, with the label `environment: staging`, and answers with the message **`staging`**.
2. **Production** runs in the namespace `podinfo-production`, takes its variables from the ConfigMap **`podinfo-prod-vars`**, answers with the message **`production from ConfigMap`**, and runs **3** replicas set by its patch.

## Constraints

- Do not change the repository, and do not apply the application's manifests yourself.
- Do not create new namespaces or new ConfigMaps. Use `podinfo-staging`, `podinfo-production` and `podinfo-prod-vars` as they are.
- Do not mark the variable source as `optional`.
- Keep the replica count in the patch of `podinfo-production`.

## Done when

- `flux get kustomizations` shows both objects `Ready`.
- Requests from the `tester` pod return `staging` from `http://podinfo.podinfo-staging:9898` and `production from ConfigMap` from `http://podinfo.podinfo-production:9898`.
- The production Deployment has 3 ready replicas.
