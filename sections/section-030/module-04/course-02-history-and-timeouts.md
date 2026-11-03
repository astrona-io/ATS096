# History And Timeouts

Every upgrade writes a new Helm Secret. Without a limit these pile up, and every one holds the full rendered manifest. And every step of a release has a time budget, after which Helm gives up. This part limits the history, reads it, and sets the timeouts for install, upgrade and the run as a whole.

## Limit the history

`spec.maxHistory` sets how many revisions Helm keeps. The default is 5. A value of 0 means no limit, which Flux discourages. When a new revision is stored and the limit is passed, the oldest Secret is deleted.

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"maxHistory":3}}'
```

Then make a few upgrades by changing a value, and watch the number of Secrets stop at three:

<!-- astrona:playground:renew -->

```sh
for n in 1 2 3 4 5; do
  kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p "{\"spec\":{\"values\":{\"ui\":{\"message\":\"run $n\"}}}}"
  flux reconcile helmrelease podinfo -n podinfo-staging
done
kubectl -n podinfo-staging get secrets -l owner=helm,name=podinfo -L version,status
```

Only the three newest revisions remain. The older ones are gone, and so is the ability to roll back to them. Keep at least two, because a rollback needs the previous revision. The default of five is a good middle.

## Timeouts

Helm waits for objects to become ready, and each wait has a limit:

| Field | Applies to | Default |
| --- | --- | --- |
| `spec.timeout` | Every Helm action of the release | 5 minutes |
| `spec.install.timeout` | The install, overrides `spec.timeout` | Not set |
| `spec.upgrade.timeout` | An upgrade, overrides `spec.timeout` | Not set |
| `spec.uninstall.timeout` | An uninstall, overrides `spec.timeout` | Not set |

A chart that needs ten minutes to settle fails with a timeout at five, and the failure then looks like a broken chart. Raise the timeout for that release, not for all of them.

## Not waiting

By default Helm waits until the Deployments, Services and other objects of the release are ready. `install.disableWait` and `upgrade.disableWait` turn that off. The release then counts as installed when the objects are created, and a Deployment that never becomes ready goes unnoticed.

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"install":{"disableWait":true}}}'
```

This is useful when readiness is checked elsewhere, for example by the Flux `Kustomization` with `wait: true`, and you do not want two timers for the same fact. Put the setting back to avoid surprises in this playground:

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"install":{"disableWait":false}}}'
```

You can now keep the storage small and give each step the time it needs. The mission uses the namespace split and the history limit.

## Common pitfalls

> [!WARNING]
> - **`maxHistory: 1`.** There is no previous revision to roll back to.
> - **`maxHistory: 0`.** Storage grows without limit and slows listing.
> - **One large timeout for everything.** A broken release then takes that long to fail.
> - **`disableWait` without another check.** A release can be `Ready` with Pods that never start.

## Your mission: Install Into A New Namespace With Separate Storage

You can now place a release, name it and limit its history. The mission asks for all three on a release you create from scratch.

Pause the playground first:

```sh
astrona stop ats-096-playground-030-04
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-030/module-04/labs/lab-01
astrona submit -c sections/section-030/module-04/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-030-04
astrona start ats-096-playground-030-04
```
