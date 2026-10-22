# Variable Substitution After The Build

Some differences between environments are not about structure but about values: a message, a label value, a hostname. A patch can set each of them, but a patch per value quickly grows longer than the object it changes. Flux has a simpler tool for values. The base names a variable, such as `${message}`, and each Flux `Kustomization` gives it a value. This part sets the message and the label of both environments that way, from inline values and from a ConfigMap.

## How substitution works

Variable substitution is the last step before the apply. After the build and the patches, kustomize-controller searches the built YAML for `${name}` and replaces it with a value. The values come from the field `postBuild` of the Flux `Kustomization`:

| Field | Where the values come from |
| --- | --- |
| `postBuild.substitute` | A map of names and values, written in the Flux `Kustomization` itself |
| `postBuild.substituteFrom` | A list of ConfigMaps and Secrets in the same namespace as the Flux `Kustomization`, each with `kind`, `name` and `optional` |

The base in your repository already uses two variables. The Deployment has the label `environment: ${environment:=dev}` and the environment variable `PODINFO_UI_MESSAGE` with the value `${message:=deployed by Flux}`. The part after `:=` is a default: kustomize-controller uses it when no value is given. A variable without a default and without a value is replaced with an empty string. `flux build kustomization --strict-substitute` makes that case fail instead, which is a good check before a commit.

## Set values inline for staging

Staging needs the label `environment: staging` and the message `staging`. Both are short and not secret, so they go straight into the Flux `Kustomization`. Change the object you created for staging so it has a `postBuild` block.

<!-- astrona:playground:renew -->

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
  postBuild:
    substitute:
      environment: staging
      message: staging
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-staging.yaml
```

Then check the result:

```sh
kubectl -n podinfo-staging get deployment podinfo -L environment
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

The `ENVIRONMENT` column shows `staging`, and the request returns the message `staging`. A change to the message changes the pod template, so the Deployment rolled out a new pod; the request may need a few seconds before it shows the new message.

## Take values from a ConfigMap for production

Production gets its values from a ConfigMap. That keeps them out of the Flux object, and the same ConfigMap can feed several Flux `Kustomization` objects. The ConfigMap must be in the same namespace as the Flux `Kustomization`, which is `flux-system`, not in the namespace of the application.

Save this as `configmap-podinfo-production-vars.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-production-vars
  namespace: flux-system
data:
  environment: production
  message: production
```

Apply it:

```sh
kubectl apply -f configmap-podinfo-production-vars.yaml
```

Now point the production copy at it. Run `kubectl -n flux-system edit kustomization podinfo-production` and add this block under `spec`, at the same level as `patches`:

```yaml
  postBuild:
    substituteFrom:
      - kind: ConfigMap
        name: podinfo-production-vars
```

Then check the result:

```sh
flux reconcile kustomization podinfo-production
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

The request returns `production`, and the Deployment carries the label `environment: production`. The keys of the ConfigMap became the variable names. A Secret works the same way with `kind: Secret`, for values that must not be readable by everyone who can read ConfigMaps.

## When a variable source is missing

`optional` is `false` unless you set it. Then a missing ConfigMap or Secret is an error: kustomize-controller stops the reconciliation, the Flux `Kustomization` becomes not ready, and the objects stay as they were. See it for yourself by renaming the reference to a ConfigMap that does not exist, `podinfo-prod-vars`, with `kubectl -n flux-system edit kustomization podinfo-production`, and reconciling:

```sh
flux reconcile kustomization podinfo-production
flux events --for Kustomization/podinfo-production
```

The reconciliation fails, and the events name the ConfigMap that kustomize-controller could not find. Put the name back to `podinfo-production-vars` and reconcile again. Setting `optional: true` would also make the error go away, but then production silently uses the defaults: the message `deployed by Flux` and the label `dev`. Use `optional: true` only for a source that is really allowed to be missing.

Two last details complete the picture. To keep a literal `${name}` in a file, write `$${name}`. To turn substitution off for one object, give it the annotation or label `kustomize.toolkit.fluxcd.io/substitute: disabled`, which you need for objects that contain shell scripts with their own `${...}`.

You can now give one base different values per environment, from the Flux object or from a ConfigMap, and you know what a missing source does. With `targetNamespace`, patches and substitution together, one folder in Git serves both environments. That is exactly what the graded lab asks you to build from scratch.

## Common pitfalls

> [!WARNING]
> - **The ConfigMap in the wrong namespace.** `substituteFrom` reads from the namespace of the Flux `Kustomization`, `flux-system` here, not from the target namespace of the application.
> - **Hiding a missing source with `optional: true`.** The error goes away and the defaults take over. The environment then runs with values nobody chose.
> - **Expecting a variable inside a patch to be replaced first.** Substitution runs after the patches, on the final YAML. A `${name}` that a patch adds is replaced too, but a patch cannot read a variable's value.
> - **Shell scripts in ConfigMaps.** Their own `${HOME}` or `${1}` gets replaced too. Write `$${HOME}`, or turn substitution off for that object.

## Your mission: Deploy One Base To Two Environments

You can now deploy one base folder twice, in two namespaces, with a patch for the size and variables for the values. The graded lab gives you a cluster with the `fleet` source and an empty staging and production, and asks you to create both Flux `Kustomization` objects so that each environment runs with its own replica count, label and message.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-096-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-096-lab-010-01
astrona start ats-096-playground-010-01
```
