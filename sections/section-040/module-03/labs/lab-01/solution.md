# Solution

## Step 1: Let team-b take the object first

If both changes were in one commit, `team-a` might reconcile first, prune the object, and `team-b` would create a new one. Do it in two commits. In the first, `team-b` starts to apply the object, and the owner labels move to it.

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In a second terminal:

```sh
git clone http://gitops:gitops-password@localhost:3000/gitops/fleet.git
cd fleet
cp apps/team-a/settings.yaml apps/team-b/settings.yaml
printf '  - settings.yaml\n' >> apps/team-b/kustomization.yaml
git add -A
git commit -m "Add shared-settings to team-b"
git push origin main
flux reconcile kustomization team-b --with-source
kubectl -n podinfo-staging get configmap shared-settings --show-labels
```

The label `kustomize.toolkit.fluxcd.io/name` now says `team-b`.

## Step 2: Let team-a go

```sh
git rm apps/team-a/settings.yaml
sed -i.bak '/settings.yaml/d' apps/team-a/kustomization.yaml
rm apps/team-a/kustomization.yaml.bak
git add -A
git commit -m "Remove shared-settings from team-a"
git push origin main
flux reconcile kustomization team-a --with-source
kubectl -n podinfo-staging get configmap shared-settings
astrona submit
```

`team-a` no longer lists the object in its build, but the object belongs to `team-b` by label, so it is not deleted. If the check says the UID changed, the object was pruned and created again: reset the lab and use two commits.
