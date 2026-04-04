variable "subscription_id" {
  description = "Azure subscription to use for the deployment. Leave null to use the default from `az login`."
  type        = string
  default     = null
}

variable "tenant_id" {
  description = "Azure tenant to use for the deployment. Leave null to use the default from `az login`."
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Resource group to contain the AKS cluster and networking."
  type        = string
  default     = "rg-opencost"
}

variable "node_resource_group_name" {
  description = "Optional resource group for AKS-managed node resources. Leave blank to let AKS create one."
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster."
  type        = string
  default     = "opencost"
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS API server. Defaults to the cluster name."
  type        = string
  default     = "opencost"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS."
  type        = string
  default     = "1.29.7"
}

variable "vnet_cidr" {
  description = "Virtual network CIDR for the cluster."
  type        = string
  default     = "10.42.0.0/16"
}

variable "aks_subnet_cidr" {
  description = "Subnet CIDR assigned to AKS nodes."
  type        = string
  default     = "10.42.0.0/20"
}

variable "api_server_authorized_ranges" {
  description = "Optional CIDR ranges allowed to reach the AKS API server."
  type        = list(string)
  default     = []
}

variable "enable_workload_identity" {
  description = "Enable OIDC/workload identity on the AKS cluster."
  type        = bool
  default     = true
}

variable "system_node_pool" {
  description = "Settings for the system node pool."
  type = object({
    name                 = string
    vm_size              = string
    count                = number
    os_disk_size_gb      = number
    max_pods             = number
    only_critical_addons = bool
    zones                = list(string)
  })

  default = {
    name                 = "system"
    vm_size              = "Standard_D4s_v5"
    count                = 3
    os_disk_size_gb      = 128
    max_pods             = 110
    only_critical_addons = true
    zones                = []
  }
}

variable "spot_node_pool" {
  description = "Configuration for the spot node pool."
  type = object({
    enabled             = bool
    name                = string
    vm_size             = string
    count               = number
    os_disk_size_gb     = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    eviction_policy     = string
    max_price           = number
    node_labels         = map(string)
    node_taints         = list(string)
    zones               = list(string)
  })

  default = {
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
}

variable "gpu_node_pool" {
  description = "Configuration for the GPU node pool."
  type = object({
    enabled             = bool
    name                = string
    vm_size             = string
    count               = number
    os_disk_size_gb     = number
    enable_auto_scaling = bool
    min_count           = number
    max_count           = number
    node_labels         = map(string)
    node_taints         = list(string)
    zones               = list(string)
  })

  default = {
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
}

variable "tags" {
  description = "Tags applied to all Azure resources."
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "The environment name (e.g., dev, staging, prod, demo)"
  type        = string
  default     = "demo"
}

variable "argo_settings" {
  type = object({
    source_repo_url = string
    target_revision = string
  })
  description = "Settings for the Argo CD installation"

  default = {
    source_repo_url = "https://github.com/trucpd/opencost-infra.git"
    target_revision = "main"
  }
}
