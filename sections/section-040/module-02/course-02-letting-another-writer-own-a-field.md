# Letting Another Writer Own A Field

An autoscaler decides the replica count of a Deployment from load. If Git says `replicas: 1`, Flux sets it back to 1 at every reconciliation, and the autoscaler and Flux take turns. The fix is not a Flux setting. It is a change in Git: the field leaves the file. This part makes that change on the staging Deployment and shows what ownership does in each step.

## Remove the field from Git

Flux owns exactly the fields that are in the YAML it applies. If `replicas` is not in the file, Flux does not send it, and so it does not claim it. Another writer can then own it alone.

Clone the repository and delete the line `replicas: 1` from `apps/podinfo/base/deployment.yaml`:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
sed -i.bak '/^  replicas: 1$/d' apps/podinfo/base/deployment.yaml
rm apps/podinfo/base/deployment.yaml.bak
git diff
git commit -am "Let the autoscaler own the replicas"
git push origin main
```

The diff shows one removed line. Ask Flux to fetch and apply:

```sh
flux reconcile kustomization podinfo-staging --with-source
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The value is 1. That is the default of a Deployment without `replicas`: when a field leaves the YAML of the only manager that owned it, the API server resets it to its default. Check the record:

```sh
kubectl -n podinfo-staging get deployment podinfo --show-managed-fields \
  -o jsonpath='{.metadata.managedFields[?(@.manager=="kustomize-controller")].fieldsV1.f:spec}{"\n"}'
```

`f:replicas` is not in the list any more.

## Let the other writer set it

Play the autoscaler. Use a field manager name that says who writes:

```sh
kubectl -n podinfo-staging patch deployment podinfo --type=merge -p '{"spec":{"replicas":4}}' --field-manager=autoscaler
flux reconcile kustomization podinfo-staging
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The value stays 4 through the reconciliation. Flux applied the Deployment again, and did not send `replicas`, so it had nothing to take back. The manager `autoscaler` is the only owner of the field.

## What this does not cover

Removing a field gives it away completely. If someone changes the value in a way you do not want, Flux does not notice. That is the price of the exception, and it is the reason to remove only the fields that have a real second writer. A real autoscaler also needs a metrics source, which the playground does not have; the manager name here only stands for it.

The same pattern fits other cases: a field that an operator fills with a default, an annotation that an admission webhook adds, or a resource request that a vertical autoscaler adjusts.

You can now give one field to another writer without changing any Flux setting. The mission does this on its own repository.

## Common pitfalls

> [!WARNING]
> - **Removing the field only in a patch.** If the base still sets it, the field is still claimed.
> - **Expecting the old value to stay.** The field returns to its default when Flux lets it go.
> - **Setting `replicas` in an overlay for an autoscaled Deployment.** The overlay claims it again.
> - **Using an unnamed writer.** Pass `--field-manager` so the record says who wrote the value.

## Your mission: Let An Autoscaler Own The Replicas

You can now remove a claim from Git and let a second writer own the field. The mission asks for it in the lab cluster.

Pause the playground first:

```sh
astrona stop ats-096-playground-040-02
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-040/module-02/labs/lab-01
astrona submit -c sections/section-040/module-02/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-040-02
astrona start ats-096-playground-040-02
```
