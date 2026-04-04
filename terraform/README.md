This folder holds the Terraform for deploying OpenCost infrastructure on Azure Kubernetes Service (AKS).

## Prerequisites

- Terraform v1.11 or newer installed locally.
- Azure CLI authenticated (`az login`) or environment variables set for a service principal (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`).
- A storage account and blob container to hold remote Terraform state.

## Backend configuration

The Terraform backend now uses Azure Blob Storage. Provide the backend settings at init time (either with `-backend-config` flags or an `.hcl` file). Example `backend.hcl`:

```
resource_group_name  = "rg-opencost-tf"
storage_account_name = "opencosttfstate"
container_name       = "tfstate"
key                  = "terraform.tfstate"
```

Initialize Terraform with:

```
terraform init -backend-config=backend.hcl
```

## Required variables

Create a `.tfvars` file to supply Azure configuration. At minimum:

```
location              = "eastus"
resource_group_name   = "rg-opencost"
cluster_name          = "opencost"
dns_prefix            = "opencost"
subscription_id       = "00000000-0000-0000-0000-000000000000" # optional if using `az login`
tenant_id             = "00000000-0000-0000-0000-000000000000" # optional if using `az login`
environment           = "demo"

# Optional: override node pools
system_node_pool = {
  name                 = "system"
  vm_size              = "Standard_D4s_v5"
  count                = 3
  os_disk_size_gb      = 128
  max_pods             = 110
  only_critical_addons = true
  zones                = []
}

spot_node_pool = {
  enabled             = true
  name                = "spot"
  vm_size             = "Standard_D4ads_v5"
  count               = 2
  os_disk_size_gb     = 150
  enable_auto_scaling = true
  min_count           = 1
  max_count           = 4
  eviction_policy     = "Delete"
  max_price           = -1
  node_labels = {
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]
  zones = []
}

gpu_node_pool = {
  enabled             = false
  name                = "gpu"
  vm_size             = "Standard_NC4as_T4_v3"
  count               = 1
  os_disk_size_gb     = 150
  enable_auto_scaling = false
  min_count           = 1
  max_count           = 2
  node_labels = {
    accelerator = "gpu"
  }
  node_taints = []
  zones       = []
}
```

You can disable the GPU pool by setting `gpu_node_pool.enabled = false` if your subscription lacks GPU quota.

## Outputs

- `kubeconfig` — path to the generated kubeconfig targeting the AKS cluster
- `aks_cluster_name` — AKS cluster name
- `resource_group_name` — resource group containing the AKS resources

## CI / DevSecOps pipeline

Pull requests and pushes run `.github/workflows/devsecops-pipeline.yaml`, which:

- Formats, inits (local backend), and validates Terraform
- Generates a local plan artifact (`terraform/tfplan`) and opens a drift issue on default-branch runs when changes are detected
- Scans IaC with `tfsec` and CodeQL (security-extended)
- Spins up a KinD cluster and performs a server-side dry-run Helm install of the iperf3 chart as a lightweight integration check

Azure OIDC credentials are required for the plan step:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
