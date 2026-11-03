# Solution: Resume And Tune A Suspended Stage

Work the task yourself first. Running `astrona submit -c sections/section-020/module-03/labs/lab-01` after a step tells you which checks pass.

The grader checks that the object is not suspended and is `Ready`, that the three timers have the requested values, and that a manual reconciliation was handled and podinfo answers `staging`.

## Step 1: Look at the stage

```sh
flux get kustomizations
kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.spec.suspend} {.spec.interval} {.spec.retryInterval} {.spec.timeout}{"\n"}'
```

The table shows `SUSPENDED` as `True`. The timers are `24h`, nothing for `retryInterval`, and `5s`.

## Step 2: Set the timers and resume

Save this as `patch-apps-staging.yaml`:

```yaml
spec:
  suspend: false
  interval: 5m
  retryInterval: 1m
  timeout: 3m
```

Apply it:

```sh
kubectl -n flux-system patch kustomization apps-staging --type=merge --patch-file patch-apps-staging.yaml
```

## Step 3: Request a reconciliation

```sh
flux reconcile kustomization apps-staging --with-source
```

The command fetches the source, applies the folder and waits for the health check. It returns when `apps-staging` is `Ready`.

## Step 4: Check and submit

```sh
flux get kustomizations
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
astrona submit -c sections/section-020/module-03/labs/lab-01
```

The message is `staging`.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Delete the object and create a new one | Pruning runs for the old object, and the grader checks that you fixed the existing one |
| Only `flux resume` | The `5s` timeout fails the first health check, and the `24h` interval hides the retry |
| Set the timers and do not resume | A suspended object never reconciles |

## Common mistakes

- Setting `timeout` longer than `interval`, which is allowed but hides a failure for a long time.
- Editing the timers and forgetting `suspend: false`.
- Running `flux reconcile` without `--with-source` and expecting a new commit.
