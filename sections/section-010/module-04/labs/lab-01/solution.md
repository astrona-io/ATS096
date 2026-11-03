# Solution: Decrypt A Secret With SOPS And Age

Work the task yourself first. Running `astrona submit -c sections/section-010/module-04/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `podinfo-secure` uses `decryption` with the provider `sops` and the Secret `sops-age` and is `Ready`; the Secret `podinfo-credentials` holds the decrypted message while the file in Git stays encrypted; and podinfo answers with the message `sealed-by-sops`.

## Step 1: Read why it is not Ready

```sh
flux get kustomizations
kubectl -n flux-system describe kustomization podinfo-secure
```

The Flux `Kustomization` is not `Ready`. The message in the status says the apply of the Secret failed. The file in Git is encrypted and the Flux `Kustomization` has no `decryption` block, so kustomize-controller has no instruction to decrypt it and builds the file as stored.

## Step 2: Check that the key exists

```sh
kubectl -n flux-system get secret sops-age -o jsonpath='{.data}' | jq 'keys'
```

The Secret has one key, `age.agekey`. The key name must end in `.agekey` for the controller to use it as an age key.

## Step 3: Add the decryption block

Save this as `podinfo-secure.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-secure
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
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

Apply it:

```sh
kubectl apply -f podinfo-secure.yaml
```

## Step 4: Reconcile and check

```sh
flux reconcile kustomization podinfo-secure --with-source
flux get kustomizations
kubectl -n podinfo-staging get secret podinfo-credentials
kubectl -n podinfo-staging rollout status deployment/podinfo
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

`podinfo-secure` is `Ready`, the Secret exists, the Deployment becomes ready and the request answers `sealed-by-sops`.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-04/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Create the Secret with `kubectl create secret` | The pod starts, but Flux still fails on the encrypted file and the grader finds a Flux `Kustomization` that is not `Ready` |
| Commit the plain text Secret | The grader finds a file in Git that is not encrypted |
| Suspend the Flux `Kustomization` | Nothing is applied and the check for a `Ready` object fails |
| Remove `secret.sops.yaml` from the folder | The Deployment has no Secret to read |

## Common mistakes

- Writing `provider: age` instead of `provider: sops`. The provider is `sops`; age is only the key type.
- Pointing `secretRef` at a Secret in another namespace. The Secret must be in the namespace of the Flux `Kustomization`.
- Forgetting that the Flux `Kustomization` object is changed in the cluster here, not in Git.

## Practice on your own

- Run `sops --decrypt` on the file with a local key and compare the output with the stored file.
- Add a second Secret to the folder, encrypt it, and check that Flux applies it with the same decryption block.
