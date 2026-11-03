# Testing An Expression

A health rule that was never tested is a guess. In a real cluster the controller of the custom resource writes the status, and you cannot easily make it write a failure. This part takes the controller's place: you write `status.phase` with `kubectl`, watch the Flux `Kustomization` react to each value, and read what the controller reports for a failed rule and a bad expression.

## Write the status by hand

The `status` of a custom resource is a separate part of the object, so a normal `kubectl apply` ignores it. The command `kubectl patch` with the flag `--subresource=status` writes it, which is exactly what a controller does. Set the phase `Starting` first:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p '{"status":{"phase":"Starting"}}'
flux reconcile kustomization widgets
flux get kustomizations
```

`Starting` matches `inProgress`, so the health check keeps waiting. The reconcile command returns with an error when the one minute `timeout` ends, and `widgets` is not ready. Waiting is the correct answer: the widget is on its way.

## Make it healthy

Now write the phase `Running` and reconcile again:

```sh
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p '{"status":{"phase":"Running"}}'
flux reconcile kustomization widgets
flux get kustomizations
```

`Running` matches `current`, and `widgets` becomes `Ready` at once. The Flux `Kustomization` did not apply anything new. It only read the status of the object and found it healthy, which is what any stage with `dependsOn` on `widgets` reads too.

## Make it fail

Write the phase `Failed`:

```sh
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p '{"status":{"phase":"Failed"}}'
flux reconcile kustomization widgets
flux events --for Kustomization/widgets
```

This time the command returns quickly instead of waiting for the `timeout`, because `failed` is true. The events show the reason `HealthCheckFailed`. The difference between waiting a minute and failing at once is the value of a `failed` expression: it turns a long wait into a fast error for states that cannot recover.

## When the expression itself is wrong

CEL is checked when kustomize-controller reads the Flux `Kustomization`. A syntax error such as a missing quote is reported as a failure of the object, and nothing is applied until you fix it. A reference to a field the object does not have is different: it is an error when the check runs, which is why `has()` appears in the expressions above. Always test both outcomes, a healthy value and an unhealthy value, before you rely on a rule.

You can now test a health rule without a controller and read the three outcomes: waiting, healthy and failed. Real objects usually report their state in conditions or counters rather than in one field, which the next part covers.

## Common pitfalls

> [!WARNING]
> - **Using `kubectl edit` or `apply` to set the status.** The `status` subresource ignores it. Use `kubectl patch --subresource=status`.
> - **Testing only the healthy case.** A rule that is always true also passes that test. Write a value that must fail and confirm that the object reports it.
> - **Expecting the status to survive a controller.** On a real cluster the controller overwrites what you wrote.

## Your mission: Gate A Custom Resource With healthCheckExprs

You can now write a health rule and test it by writing the status yourself. The mission asks you to do both for a Widget in a prepared repository.

Pause the playground first:

```sh
astrona stop ats-096-playground-020-02
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-020/module-02/labs/lab-01
astrona submit -c sections/section-020/module-02/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-020-02
astrona start ats-096-playground-020-02
```
