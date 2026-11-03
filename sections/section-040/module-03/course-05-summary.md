# Summary

A Flux `Kustomization` keeps a record of every object it applied, called the inventory, and writes owner labels on each object it applies. The record answers what the stage applied last time. The labels answer who owns an object now.

Pruning deletes an object only when it is in the last inventory, is not in the new build, and still carries the owner labels of that stage. Objects created by hand, objects owned by another stage, objects with the annotation `kustomize.toolkit.fluxcd.io/prune: disabled` and every object of a stage with `prune: false` are never deleted.

Moving an object between stages takes two commits. The first adds the file to the new stage, so both stages apply the same object. The second removes it from the old stage, which then skips it because the labels name the new stage. The UID of the object stays the same.

Deleting a Flux `Kustomization` follows `spec.deletionPolicy`. The default, `MirrorPrune`, follows `prune`. `Delete` and `WaitForTermination` remove the objects, and `Orphan` leaves them in the cluster without an owner.

<!-- astrona:playground:destroy -->
