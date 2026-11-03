# Choosing The Smallest Exception

There are several ways to keep a field, an object or a whole stage out of Flux's reach. They differ in how much they give away and in who can see the exception afterwards. This part puts them side by side and gives a rule for choosing, so that the exception you pick is the narrowest one that works.

## The options

| Option | What it frees | Where it is written | How it is undone |
| --- | --- | --- | --- |
| Remove the field from Git | One field | The YAML in Git | Add the field back |
| Add the field with the manager `flux-client-side-apply` | One added field Git does not set | The live object | Delete the field |
| `ssa: Merge` on an object | Fields that other managers added | The YAML in Git | Remove the annotation |
| `ssa: IfNotPresent` on an object | Everything after the first creation | The YAML in Git | Remove the annotation |
| `reconcile: disabled` on an object | The object, including pruning | The YAML in Git | Remove the annotation |
| `prune: disabled` on an object | Deletion of the object | The YAML in Git | Remove the annotation |
| `suspend: true` on a Flux `Kustomization` | The whole stage | The object in Git or the cluster | `flux resume` |

The table is ordered from narrow to wide. The first option affects one field, the last one stops a whole stage.

## A rule for choosing

Ask four questions in order:

1. Is there a second writer for exactly this field? Remove the field from Git.
2. Is it a field that Git never sets, such as a label added for tracking? Add it with the manager `flux-client-side-apply`, or leave it to the other writer.
3. Is it one object that must not change after creation? Use `ssa: IfNotPresent` on that object, and write down why.
4. Is it an emergency that needs the stage frozen? Suspend it, and resume it as soon as the cause is fixed.

The exceptions in the YAML are visible to everyone who reads the repository. The exceptions in the live object, and a suspended stage, are not, and are easy to forget. Prefer the first kind.

## Check what you gave away

After you choose, prove the size of the exception with the tools from this module. Diff the folder against the cluster, then read the managers:

<!-- astrona:playground:renew -->

```sh
flux diff kustomization podinfo-staging --path ./apps/podinfo/base
kubectl -n podinfo-staging get deployment podinfo --show-managed-fields \
  -o jsonpath='{range .metadata.managedFields[*]}{.manager}{"  "}{.operation}{"\n"}{end}'
```

An exception that frees one field shows a diff for that field and nothing else. If the diff is larger than you intended, the exception is wider than you meant.

Write each exception with a reason next to it, in the commit message or in a comment in the file. The next person who reads the object should not need to rebuild the reasoning from the managed fields.

You can now choose the smallest exception for a given need and check how large it is. Together with the parts before, you can share a live object between Flux and other writers without fights, and without losing sight of what Git no longer controls.

## Common pitfalls

> [!WARNING]
> - **Reaching for `suspend` first.** It frees everything and is easy to forget.
> - **`IfNotPresent` on a Deployment that still changes.** Updates in Git silently never arrive.
> - **An exception without a reason.** Nobody can tell later whether it is still needed.
> - **Checking only that the app works.** Check the diff to see what else was freed.
