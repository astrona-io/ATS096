# Decrypt Secrets With SOPS And Age

A Kubernetes Secret holds its values as base64, which is an encoding and not encryption. If you commit a Secret to Git, everyone who can read the repository reads the value. GitOps wants everything in Git, including secrets, so the secret has to be encrypted before it is committed, and something in the cluster has to decrypt it. This part builds that with SOPS, age and the `decryption` field of a Flux `Kustomization`.

## The three pieces

**age** is a small tool for file encryption. It makes a key pair: a public key that anyone may use to encrypt, and a private key that decrypts. **SOPS** is a tool that encrypts the values inside a YAML file and leaves the keys and structure readable, so a diff in Git still shows which field changed. **kustomize-controller** can run SOPS itself: when a Flux `Kustomization` has a `decryption` block, the controller decrypts every SOPS-encrypted file it builds, using a private key from a Secret in the cluster.

```mermaid
flowchart LR
    A["plain Secret file"] -->|"sops + age public key"| B["encrypted file in Git"]
    B -->|"source-controller"| C["kustomize-controller"]
    D["Secret sops-age (private key)"] --> C
    C -->|"decrypt, then apply"| E["Secret in the cluster"]
```

Only the public key ever leaves your machine in a command. The private key goes into the cluster once, and nowhere else.

## Create the key and give it to Flux

Make a working folder outside any repository, then create the key pair:

<!-- astrona:playground:renew -->

```sh
mkdir -p ~/sops-demo && cd ~/sops-demo
age-keygen -o age.agekey
age-keygen -y age.agekey
```

The first command writes the private key to `age.agekey`. The second prints the matching public key, a string that starts with `age1`. Keep that string for the next step.

Store the private key as a Secret in the namespace of the Flux `Kustomization`, which is `flux-system` here. The key name must end in `.agekey` so that the controller recognizes it as an age key:

```sh
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey=age.agekey
```

## Encrypt a Secret

Clone the repository. This needs the port-forward to Gitea to run in a second terminal.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
```

Save this as `apps/podinfo/base/secret.sops.yaml`. It is still plain text, so do not commit it yet:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-credentials
type: Opaque
stringData:
  message: hello-from-sops
```

Encrypt it in place. Replace the value after `--age` with your public key. The option `--encrypted-regex` limits encryption to the fields `data` and `stringData`, so the name and kind stay readable:

```sh
sops --encrypt --age age1-your-public-key-here \
  --encrypted-regex '^(data|stringData)$' \
  --in-place apps/podinfo/base/secret.sops.yaml
cat apps/podinfo/base/secret.sops.yaml
```

The file now has the same `apiVersion`, `kind` and `metadata`. The value of `message` is an `ENC[...]` string, and a `sops` block at the end holds the encrypted data key, the public key that was used and a message authentication code. The plain text is gone.

To avoid typing the options each time, a file named `.sops.yaml` at the top of the repository sets them once:

```yaml
creation_rules:
  - path_regex: .*\.sops\.yaml$
    encrypted_regex: ^(data|stringData)$
    age: age1-your-public-key-here
```

Add the encrypted file to the Kustomize file `apps/podinfo/base/kustomization.yaml`, under `resources`, next to the Deployment and the Service. Then commit and push:

```sh
git add apps/podinfo/base
git commit -m "Add the encrypted podinfo-credentials Secret"
git push origin main
```

## Apply it with and without decryption

First apply a Flux `Kustomization` that has no `decryption` block. Save this as `podinfo-secure.yaml`:

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
```

```sh
kubectl apply -f podinfo-secure.yaml
flux get kustomizations
kubectl -n flux-system describe kustomization podinfo-secure
```

The Flux `Kustomization` does not become `Ready`. The controller has no instruction to decrypt, so it builds the encrypted file as stored, and the apply of that Secret fails. The status message and the events show the failure.

Now add the `decryption` block. Change `podinfo-secure.yaml` so that the spec ends like this, and apply the file again:

```yaml
  sourceRef:
    kind: GitRepository
    name: fleet
  decryption:
    provider: sops
    secretRef:
      name: sops-age
```

```sh
kubectl apply -f podinfo-secure.yaml
flux reconcile kustomization podinfo-secure --with-source
kubectl -n podinfo-staging get secret podinfo-credentials
kubectl -n podinfo-staging get secret podinfo-credentials -o jsonpath='{.data.message}' | base64 -d
```

This time the Flux `Kustomization` becomes `Ready`. The Secret exists in `podinfo-staging`, and its decoded value is `hello-from-sops`. In Git, the file is still encrypted. Only the cluster holds the plain value.

## How it behaves

The field `provider` accepts `sops`, and `secretRef.name` names a Secret in the same namespace as the Flux `Kustomization`. The controller decrypts every file in the build that has a `sops` block. A file without that block is applied as written, so an unencrypted Secret in Git is applied and also stays readable in Git. Decryption protects the repository, not the cluster: anyone who can read Secrets in `podinfo-staging` reads the value, and anyone who can read `sops-age` in `flux-system` can decrypt everything.

Key rotation is a normal task. Create a new key pair, add its public key to the creation rules, run `sops updatekeys` on each file, and give the controller the new private key before you remove the old one. Until the new Secret is in place, files encrypted to the new key fail the same way as in the first test.

## Common pitfalls

> [!WARNING]
> - **Committing the file before encrypting it.** Git keeps the plain text in its history even if you encrypt later. Encrypt first, then `git add`.
> - **Committing `age.agekey`.** The private key belongs in the cluster Secret only. Keep it outside the repository.
> - **Naming the key without the `.agekey` ending.** The controller does not use the entry as an age key.
> - **Putting `sops-age` in another namespace.** The `secretRef` is read from the namespace of the Flux `Kustomization`.
> - **Encrypting the whole file.** Without `--encrypted-regex` SOPS also encrypts the name and kind, and the diffs in Git tell you nothing.

## Your mission: Decrypt A Secret With SOPS And Age

You can now encrypt a Secret and let Flux decrypt it. The graded lab gives you a cluster where the encrypted Secret and the age key are already in place and a Flux `Kustomization` that cannot become `Ready`. You find out why and fix the Flux `Kustomization`.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-096-playground-010-04
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-010/module-04/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-04/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-096-lab-010-04
astrona start ats-096-playground-010-04
```
