# Summary

A Flux `Kustomization` applies what its source holds, with the permissions of the account it runs as. Encryption, impersonation, the choice of source and the pause controls protect each of those two sides.

## What you learned

SOPS with age keeps a Secret in Git without exposing its value. You create an age key pair, store the private key as a Secret in the namespace of the Flux `Kustomization` with a key name that ends in `.agekey`, and encrypt only the `data` or `stringData` of the Secret file with the public key. The field `decryption` with the provider `sops` and a `secretRef` makes kustomize-controller decrypt every encrypted file in the build. Without it, the encrypted file is built as stored and the apply fails. Encryption protects the repository, not the cluster: anyone who reads the Secret in the cluster, or the key Secret, reads the value.

By default, kustomize-controller applies with its own account, which has cluster administrator rights. The field `serviceAccountName` makes it apply, wait and prune as a ServiceAccount from the namespace of the Flux `Kustomization`, so that RBAC limits what a folder in Git can touch. The Role needs read and watch verbs as well as write verbs, because the controller compares, waits and prunes. A missing rule shows up as a forbidden error in the status.

The field `sourceRef` names a `GitRepository`, an `OCIRepository` or a `Bucket`. A Git source gives history, an OCI source gives immutable versioned artifacts, and a bucket gives the current files only. The field `sourceRef.namespace` reads a source from another namespace, and the controller flag `--no-cross-namespace-refs` turns that off for the whole cluster.

`flux suspend kustomization` stops reconciliation without deleting anything, and `flux resume kustomization` applies the current state at once. The annotation `kustomize.toolkit.fluxcd.io/reconcile: disabled` pauses one live object, and `kustomize.toolkit.fluxcd.io/prune: disabled` keeps an object that leaves Git. Deleting a Flux `Kustomization` with `prune: true` removes what it applied, so suspend it instead. The key facts to remember are these:

- Encrypt before you commit, and keep the private key out of Git.
- `provider: sops` and a `secretRef` in the same namespace turn decryption on.
- `serviceAccountName` limits what an apply can change.
- Suspend, do not delete, to pause Flux.

<!-- astrona:playground:destroy -->
