# Disabled ApplicationSets

`opencost-root-app` syncs only `argocd/appsets` (`terraform/argo-app.tf`). Files in this directory are kept in the repo and are not deployed.

To re-enable Folding@home, move `folding-at-home-argo.yaml` back to `argocd/appsets/`.
