# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** moving objects between stages

## Scenario

Two Flux `Kustomization` objects in `flux-system` apply folders of the repository `gitops/fleet` into `podinfo-staging`, both with pruning on: `team-a` applies `./apps/team-a` and `team-b` applies `./apps/team-b`. The ConfigMap `shared-settings` is applied by `team-a` today. Other workloads read it, so it must not be deleted or recreated: its UID must stay the same.

## Your task

Move the file `settings.yaml` that defines `shared-settings` from `apps/team-a` to `apps/team-b` in Git, and update both `kustomization.yaml` files. The object must end up owned by `team-b`.

## Constraints

- Do not delete the ConfigMap by hand.
- Do not turn off pruning on either stage.
- Do not suspend either stage.

## Done when

- Git holds `settings.yaml` under `apps/team-b` and not under `apps/team-a`.
- `shared-settings` carries the owner label `kustomize.toolkit.fluxcd.io/name: team-b`.
- The UID of `shared-settings` is the one it had at the start.
- `team-a` and `team-b` are `Ready`.
