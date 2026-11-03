# Preview Builds Locally

A push to Git is the slowest way to find out that a build is wrong. The commit lands, source-controller fetches it, kustomize-controller fails, and you read the failure minutes later. Three commands show the same result on your machine before you push. This part compares them, shows what each one can and cannot do, and uses them on the playground overlay.

## Three commands, three levels

The first command is `kubectl kustomize <folder>`. It runs only the Kustomize build on a local folder. It knows nothing about Flux: `targetNamespace`, `patches` and `postBuild` of a Flux `Kustomization` do not exist for it, and it never replaces `${variables}`. It needs no cluster at all.

The second command is `flux build kustomization <name> --path <folder>`. It reads the Flux `Kustomization` with that name from the cluster, then builds the local folder with the same code kustomize-controller uses. It applies `targetNamespace`, `patches`, `components` and the other build fields, and it replaces variables. Variables that come from a ConfigMap or Secret in the cluster are read from the cluster. It prints the final YAML and changes nothing.

The third command is `flux diff kustomization <name> --path <folder>`. It does what `flux build` does, then asks the cluster what it would change with a server-side dry run, and prints the differences. It exits with `0` when nothing would change and with `1` when something would. That exit code makes it usable in a pipeline.

| Command | Needs the cluster | Flux fields applied | Variables replaced |
| --- | --- | --- | --- |
| `kubectl kustomize` | No | No | No |
| `flux build kustomization` | Yes, to read the object | Yes | Yes |
| `flux diff kustomization` | Yes | Yes | Yes |

## Build the overlay with each command

Use the clone and the Flux `Kustomization` `podinfo-staging` from the playground. If you do not have them yet, clone the repository with the port-forward running, and save and apply a Flux `Kustomization` named `podinfo-staging` with `path: ./apps/podinfo/overlay`, `targetNamespace: podinfo-staging`, `prune: true` and `sourceRef` to the `GitRepository` `fleet`.

<!-- astrona:playground:renew -->

Run the first two commands from the root of your clone and compare the output:

```sh
kubectl kustomize apps/podinfo/overlay > kustomize.yaml
flux build kustomization podinfo-staging --path ./apps/podinfo/overlay > flux.yaml
diff kustomize.yaml flux.yaml
```

The main difference to look for is the namespace. The Flux build puts `namespace: podinfo-staging` on every namespaced object, because the Flux `Kustomization` has `targetNamespace`, and the Kustomize tool alone leaves it out, as the overlay sets none. The replaced message is the same in both files.

Now change something and see what `flux diff` reports. Edit `apps/podinfo/overlay/settings.yaml` in your clone and change the message from `from-replacement` to `preview-only`. Do not commit it. Then run:

```sh
flux diff kustomization podinfo-staging --path ./apps/podinfo/overlay
echo $?
```

`flux diff` compares your local folder with what runs in the cluster. It reports the ConfigMap `podinfo-settings` with the changed message, and the Deployment with the changed environment variable, because the replacement copies the new message into it. The exit code is `1`. The cluster is unchanged: the command only asked the API server what it would do.

## Build without a cluster

Sometimes you have no cluster, for example in a pipeline for pull requests. `flux build kustomization` can then read the Flux `Kustomization` from a file. The flag `--dry-run` makes it run without any cluster access, and `--kustomization-file` names the file. Variables that need a ConfigMap or Secret from the cluster cannot be resolved in this mode, so only inline `postBuild.substitute` values are replaced.

Save the Flux object as a local file, for example `ks.yaml` with the same content as `kustomization-podinfo-staging.yaml`. Then run:

```sh
flux build kustomization podinfo-staging --path ./apps/podinfo/overlay --kustomization-file ks.yaml --dry-run
```

The output is the final YAML, and the command did not need to reach the cluster for the Flux object. This is the command to put in a CI job that checks every pull request builds.

## Catch missing variables

Variable substitution has a quiet failure: a `${name}` without a value is replaced by an empty string, unless it has a default. The flag `--strict-substitute` on `flux build` and `flux diff` makes a variable without a value an error instead:

```sh
flux build kustomization podinfo-staging --path ./apps/podinfo/overlay --strict-substitute
```

The overlay has no variables, so this build succeeds. On a folder that has a `${message}` with no value and no default, the same command stops with an error that names the variable. Use it in CI to catch a typo in a variable name before it reaches a cluster.

Revert your change in the clone with `git checkout apps/podinfo/overlay/settings.yaml`.

You can now preview a build at three levels and read the exit code of `flux diff`. The open question is what to do when the failure is already in the cluster, where only the status and the logs of kustomize-controller remain.

## Common pitfalls

> [!WARNING]
> - **Trusting `kubectl kustomize` for a Flux `Kustomization` that uses `postBuild`.** It never replaces variables and never applies Flux fields. Use `flux build`.
> - **Running `flux diff` and reading "no differences" as "correct".** It only says that the cluster already matches the folder. A target that selects nothing also gives no differences.
> - **Using a `--path` that is not the `spec.path` of the object.** The command builds the folder you give it. A different path builds a different folder.
> - **Forgetting that `flux diff` exits with `1` on differences.** In a CI job this fails the step, which is the point. Handle the code on purpose when you only want to print.
