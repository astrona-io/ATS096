# Seeing Drift Before You Fix It

Correcting drift is only half of the job. Before you let a controller change a live object, you want to see what it would change, and afterwards you want to know what it did. This part shows three ways to look: a diff between a folder and the cluster, the events of a reconciliation, and the field managers of an object. None of them changes the cluster.

## Diff a folder against the cluster

`flux diff kustomization` builds a local folder the way kustomize-controller would, using the settings of the named Flux `Kustomization`, and compares the result with the live objects. Clone the repository and change a file without pushing it:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
sed -i.bak 's/replicas: 1/replicas: 3/' apps/podinfo/base/deployment.yaml
flux diff kustomization podinfo-staging --path ./apps/podinfo/base
```

The command prints the difference as a diff: the field `replicas` changes from 1 to 3. The exit code is 1 when there are differences and 0 when there are none, so the command can run in a pipeline. Nothing was applied, and nothing was pushed. Restore the file when you are done:

```sh
mv apps/podinfo/base/deployment.yaml.bak apps/podinfo/base/deployment.yaml
flux diff kustomization podinfo-staging --path ./apps/podinfo/base
```

With the original file, there is no difference and the exit code is 0.

Now change the live object by hand and diff again:

```sh
kubectl -n podinfo-staging scale deployment podinfo --replicas=5
flux diff kustomization podinfo-staging --path ./apps/podinfo/base
```

The diff shows `replicas` going from 5 back to 1. This is the drift: the folder, which equals Git, differs from the cluster. The diff is what the next reconciliation would do. Run `flux reconcile kustomization podinfo-staging` and diff again to see it disappear.

## Read what a reconciliation did

kustomize-controller writes an event for each reconciliation. After the reconcile above, read them:

```sh
flux events --for Kustomization/podinfo-staging
```

An event that lists an object as configured means that the apply changed it. An event that lists nothing means the live objects already matched. Corrected drift is therefore visible after the fact, which matters because it happens without anyone asking.

The status adds the revisions: `lastAppliedRevision` is the commit that is live, and `lastAttemptedRevision` is the one the controller tried last.

```sh
kubectl -n flux-system get kustomization podinfo-staging -o jsonpath='{.status.lastAppliedRevision}{"\n"}'
```

## Read the managers of one field

The diff tells you what differs. The managed fields tell you who set it. Print the managers of the Deployment again after a manual change made with `kubectl scale`:

```sh
kubectl -n podinfo-staging scale deployment podinfo --replicas=5
kubectl -n podinfo-staging get deployment podinfo --show-managed-fields \
  -o jsonpath='{range .metadata.managedFields[*]}{.manager}{"  "}{.operation}{"\n"}{end}'
```

A second manager appears for the scale, with the operation `Update`. The field `replicas` now has two writers in the history: Git through kustomize-controller, and the command you ran. After the next reconciliation the value is Git's again. Reading the list before and after shows whether a manual change was kept or taken back.

You can now preview a change, see what a reconciliation changed, and tell who owns a field. These tools make the policies of the next modules easier to check, and they are the tools to use before you decide that a field should be left alone.

## Common pitfalls

> [!WARNING]
> - **Diffing the wrong folder.** The `--path` must be the same folder as `spec.path` of the Flux `Kustomization`, or the diff compares different objects.
> - **Reading exit code 1 as a failure.** For `flux diff`, 1 means differences were found.
> - **Forgetting variables.** `flux diff` uses the `postBuild` settings of the Flux `Kustomization`; a folder with other variables is built differently.
> - **Pushing the experiment.** Restore the changed file before `git commit -a`.
