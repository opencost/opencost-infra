# Disabled ApplicationSets

`opencost-root-app` syncs only `argocd/appsets` (`terraform/argo-app.tf`). Files in this directory are kept in the repo and are not deployed.

To re-enable Folding@home, move `folding-at-home-argo.yaml` back to `argocd/appsets/`.

To turn off the llm-d A10 stack, move these ApplicationSets here:

- `llm-d-gaie-crds-argo.yaml`
- `llm-d-gateway-argo.yaml`
- `llm-d-router-argo.yaml`
- `llm-d-argo.yaml`
