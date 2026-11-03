# Diagnosing A Stuck Pipeline

A pipeline of Flux `Kustomization` objects fails in a small number of ways, and each one leaves a different trace. The skill that matters in practice is reading the trace quickly: which object is stuck, what it waits for and why. This part gives you a fixed order of commands for that, and shows the three common causes of a stuck stage: a dependency that is not ready, a dependency that does not exist and a dependency loop.

## Read the pipeline from the top

Start with the whole list. The command `flux get kustomizations` prints one row for each Flux `Kustomization`, with its `READY` value, its revision and its message. A stage that is waiting shows `READY` as `False` and a message that names the dependency. A stage that has already failed its own health check shows the message of the health check instead.

<!-- astrona:playground:renew -->

```sh
flux get kustomizations
```

The first stage that is not ready is the one to look at. Stages behind it show the reason `DependencyNotReady`, which is a consequence and not a cause. Follow the chain upstream until you reach a stage whose message is not about a dependency. That stage holds the real problem.

## Read the events of the stuck object

The messages in the table are cut short. The events of one object keep the full text and the reason of each reconciliation:

```sh
flux events --for Kustomization/apps-staging
kubectl -n flux-system describe kustomization apps-staging
```

In the output of `describe`, the block `Conditions` lists `Ready`, and often `Reconciling` and `Healthy`. The condition `Ready` has a `Reason` and a `Message`. The reason `DependencyNotReady` means a named dependency is not `Ready` yet. The reason `HealthCheckFailed` means the apply worked and a workload did not become healthy in time. The reason `BuildFailed` means the folder did not build, for example because of a wrong path or an invalid patch.

## A dependency that does not exist

`dependsOn` takes a name and a namespace. When no Flux `Kustomization` with that name exists in that namespace, kustomize-controller treats the dependency as not ready. The message says that the dependency was not found. Flux does not tell you that you made a typo, so the stage waits for ever with a message that looks like a normal wait.

Compare the names in `dependsOn` with the names in `flux get kustomizations`. The namespace matters too: an entry without `namespace` means the namespace of the object that holds the entry.

```sh
kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.spec.dependsOn}'
kubectl -n flux-system get kustomization
```

## A dependency loop

If `apps-staging` depends on `apps-production` and `apps-production` depends on `apps-staging`, neither stage can ever become `Ready`. kustomize-controller does not detect the loop. Both objects report `DependencyNotReady` for ever.

The command `flux tree kustomization apps-production` prints what an object manages and does not show dependencies, so read the loop from the `dependsOn` fields. List every object with its dependencies in one command, then look for two names that point at each other:

```sh
kubectl -n flux-system get kustomization -o jsonpath='{range .items[*]}{.metadata.name}{" -> "}{.spec.dependsOn[*].name}{"\n"}{end}'
```

Break the loop by removing one entry. The stage that was waiting reconciles on its next retry, or at once if you run `flux reconcile kustomization <name>`.

## What to do after the fix

After you correct a field in Git, the fix reaches the cluster at the next interval of the source and of the object. To skip the wait, run `flux reconcile kustomization <name> --with-source`, which makes source-controller fetch the new commit first. When you correct the Flux object itself with `kubectl`, plain `flux reconcile kustomization <name>` is enough.

You can now find the stage that holds the real problem, read its reason, and tell a wait from a typo or a loop. The open question is how long a stuck stage keeps trying, which depends on the timeout and retry fields of that stage and on the reconciliation cycle of Flux.

## Common pitfalls

> [!WARNING]
> - **Fixing the stage that shows `DependencyNotReady`.** That stage is the victim. Find the upstream stage with a different message.
> - **Trusting the table message.** It is cut short. Read the events or `describe` for the full text.
> - **Reading a typo as a slow dependency.** A dependency that does not exist never becomes ready. Compare the names before you wait.
> - **Leaving a loop in place.** Flux never reports a loop as an error. The two objects wait for each other for ever.
