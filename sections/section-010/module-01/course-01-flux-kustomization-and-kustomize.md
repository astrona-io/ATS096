# The Flux Kustomization And Kustomize

Before you change what Flux applies, you need to know what Flux does with a folder in the first place. A Flux `Kustomization` looks like a pointer to a folder, but kustomize-controller runs a whole build on that folder every time it reconciles. This part follows one build from the artifact to the cluster, compares it with the Kustomize command-line tool, and shows you two commands that preview a build before Flux applies it.

## What kustomize-controller does with a folder

A Flux `Kustomization` is the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`. It names a source and a `path` inside it. **Kustomize** is the tool that builds a set of YAML files into final Kubernetes manifests, and kustomize-controller has it built in. The Kustomize file `kustomization.yaml` is that tool's configuration file in a folder. It lists the files of the folder and can add patches of its own.

On every reconciliation, kustomize-controller runs the same steps in the same order:

```mermaid
flowchart TB
    A["artifact of fleet"] -->|"path"| B["Kustomize build"]
    B -->|"targetNamespace, patches"| O["Flux overlay"]
    O -->|"postBuild"| S["variable substitution"]
    S -->|"server-side apply"| C["cluster"]
```

The diagram shows the build: kustomize-controller builds the folder, applies the changes from its own fields, replaces the variables, and only then applies the result.

First, kustomize-controller downloads the artifact of the source, the `tar.gz` file of one commit that source-controller serves inside the cluster. Then it builds the folder in `path` with Kustomize. If the folder has no Kustomize file `kustomization.yaml`, kustomize-controller generates one that lists every Kubernetes manifest in the folder and its subfolders. Next, it applies its own fields on top, such as `targetNamespace` and `patches`. Then it replaces `${variables}` in the built YAML. Last, it applies the result to the cluster with server-side apply.

The order matters, because each step sees only the output of the step before it. A patch never sees a `${variable}` replaced, because substitution runs after the patches. And the Kustomize command-line tool runs only the build step, so it never replaces a variable at all.

## Build the base with Kustomize

The repository holds the base for `podinfo` in `apps/podinfo/base`. Start the port-forward to Gitea in a second terminal and leave it running. `gitea.localtest.me` resolves to `127.0.0.1`; if your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

<!-- astrona:playground:renew -->

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In your first terminal, clone the repository and build the base folder with Kustomize, the way you would without Flux:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
kubectl kustomize apps/podinfo/base
```

The output is the Deployment and the Service, each as one YAML document, with no namespace. The Deployment still carries the text `${environment:=dev}` in its labels and `${message:=deployed by Flux}` in the environment variable `PODINFO_UI_MESSAGE`. Kustomize does not know these variables: they are plain text to it. kustomize-controller replaces them later, in its substitution step.

## Apply the base with a Flux Kustomization

Now let kustomize-controller build the same folder. The Flux `Kustomization` below points at the base and puts every object in the namespace `podinfo-staging`. The field `targetNamespace` does that; the next part explains it in detail.

Save this as `kustomization-podinfo-staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-staging.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

The row for `podinfo-staging` shows `READY` as `True`. The request from the `tester` pod returns the message `deployed by Flux`. No value was given for `message`, so kustomize-controller used the default after `:=`. The label `environment` on the Deployment has the value `dev` for the same reason.

## Preview a build with flux build and flux diff

You do not have to apply a change to see what it does. `flux build kustomization` runs the same steps as kustomize-controller on a folder on your machine: it reads the Flux `Kustomization` from the cluster, builds your local folder, applies the Flux fields and replaces the variables. Run it from the root of your clone:

```sh
flux build kustomization podinfo-staging --path ./apps/podinfo/base
```

This time the Deployment has the namespace `podinfo-staging`, the label `environment: dev` and the message `deployed by Flux`. That is the exact YAML kustomize-controller applies, built from your local files. Add `--dry-run` to build without reading anything from the cluster; variables from ConfigMaps and Secrets are skipped in that mode.

`flux diff kustomization` goes one step further and compares the build with what is in the cluster now:

```sh
flux diff kustomization podinfo-staging --path ./apps/podinfo/base
echo $?
```

Your clone matches the cluster, so the command reports no differences and exits with `0`. When it finds differences, it prints them and exits with `1`, which makes it useful in a pull request check. Change `replicas: 1` to `replicas: 2` in `apps/podinfo/base/deployment.yaml` without committing, run the diff again, and you see the change Flux would make. Put the file back with `git checkout apps/podinfo/base/deployment.yaml`.

You now know the steps kustomize-controller runs and which of them the Kustomize tool skips. You can preview a build and compare it with the cluster before you commit. The open question is how to make two environments from one base, which the fields `targetNamespace` and `patches` answer.

## Common pitfalls

> [!WARNING]
> - **Checking variables with `kubectl kustomize`.** It never replaces `${variables}`. Use `flux build kustomization` to see the YAML Flux really applies.
> - **Mixing up the two `Kustomization` kinds.** The Flux object lives in the cluster and points at a folder. The Kustomize file `kustomization.yaml` lives in the folder and lists its files.
> - **Running `flux build` from the wrong folder.** `--path` is relative to where you run the command. Run it from the root of your clone, with the same path as in `spec.path`.
> - **Reading a `flux diff` exit code of `1` as an error.** It means differences were found. An error exits with a code greater than `1`.
