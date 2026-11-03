# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** values and post-rendering

## Scenario

The repository `gitops/fleet` holds a small chart in `charts/hello`. It writes one ConfigMap named `<release>-config` with the key `message`, taken from the value `message`. The namespace `podinfo-staging` holds a ConfigMap `hello-message` with the key `message` set to `from-configmap`. The `GitRepository` `fleet` in `flux-system` is `Ready`. No `HelmRelease` exists yet.

The chart has no value for annotations. Operations wants the rendered ConfigMap to carry the annotation `owner: platform`.

## Your task

Create a `HelmRelease` named `hello` in the namespace `podinfo-staging`, with an `interval` of `10m`, that installs `./charts/hello` from the `GitRepository` `fleet` in `flux-system`.

1. Read the message from the key `message` of the ConfigMap `hello-message` into the value `message` with `valuesFrom` and `targetPath`.
2. Add the annotation `owner: platform` to the rendered ConfigMap `hello-config` with a Kustomize post-renderer patch.

## Constraints

- Do not change the repository.
- Do not set the message with `spec.values`.
- Do not edit the ConfigMap `hello-config` by hand.

## Done when

- `flux get helmreleases -n podinfo-staging` shows `hello` `Ready`.
- The ConfigMap `hello-config` holds the message `from-configmap` and the annotation `owner: platform`.
- The release uses `valuesFrom` with a `targetPath` and a post-renderer patch.
