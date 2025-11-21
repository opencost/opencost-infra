variable "region" {
  description = "The tenancy's home region. Use the short form in lower case e.g. phoenix."
  type        = string
  default     = "us-ashburn-1"
}

variable "availability_domain" {
  description = "The availability domain within the OCI region where resources will be deployed. avRo:US-ASHBURN-AD-2 is the only AD in Ashburn that contains the VM.GPU2.1 GPU node shape."
  type        = string
  default     = "avRo:US-ASHBURN-AD-2"
}

variable "tenancy_id" {
  description = "The tenancy id of the OCI Cloud Account in which to create the resources."
  type        = string
  sensitive   = true
}

variable "compartment_id" {
  description = "The compartment id where to create all resources."
  type        = string
  sensitive   = true
}

variable "user_id" {
  description = "The id of the user that Terraform will use to create the resources."
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint of the API Key"
  type        = string
  sensitive   = true
}

variable "image_id" {
  description = "The OCID of the image to use for the nodes"
  type        = string
  default     = "ocid1.image.oc1.iad.aaaaaaaauekp2xtllqoidhftbjbt2nifzeihrfxwn7pqjce2nrupiqjs74lq"
}

variable "nodepools" {
  type        = any
  description = "Node pools for all clusters"
  default = {
    np2 = {
      shape            = "VM.Optimized3.Flex"
      ocpus            = 2,
      memory           = 32,
      size             = 5,
      boot_volume_size = 150,
    },
    np-spot = {
      shape            = "VM.Optimized3.Flex"
      ocpus            = 2,
      memory           = 32,
      size             = 2,
      boot_volume_size = 150,

      preemptible_config = {
        enable = true
        is_preserve_boot_volume = false
      }
    }
  }
}

variable "gpu_node_shape" {
  type    = string
  default = "VM.GPU.A10.1"
}

variable "gpu_node_pool_name" {
  type    = string
  default = "np1"
}

variable "spot_node_pool_name" {
  type        = string
  description = "Name of the spot node pool"
  default     = "np-spot"
}

variable "spot_node_shape" {
  type        = string
  description = "Shape to use for spot nodes"
  default     = "VM.Standard3.Flex"
}

variable "spot_node_ocpus" {
  type        = number
  description = "Number of OCPUs for spot nodes (used for Flex shapes)"
  default     = 2
}

variable "spot_node_memory_in_gbs" {
  type        = number
  description = "Memory in GBs for spot nodes (used for Flex shapes)"
  default     = 16
}

variable "spot_node_pool_size" {
  type        = number
  description = "Desired number of spot worker nodes"
  default     = 2
}

variable "spot_node_boot_volume_size_gbs" {
  type        = number
  description = "Boot volume size for spot worker nodes"
  default     = 150
}

variable "spot_preemption_action_type" {
  type        = string
  description = "OCI preemption action when spot nodes are reclaimed (e.g., TERMINATE)"
  default     = "TERMINATE"
}

variable "spot_preserve_boot_volume" {
  type        = bool
  description = "Whether to preserve boot volumes for spot nodes after preemption"
  default     = false
}

variable "vcn_name" {
  description = "Name of the Virtual Cloud Network, same as cluster name"
  type        = string
  default     = "opencost"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "opencost"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster and node pools"
  type        = string
  default     = "v1.31.1"
}

variable "path_to_private_key" {
  description = "The path to the private key used to authenticate with OCI"
  type        = string
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
    source_repo_url = "https://github.com/opencost/opencost-infra.git"
    target_revision = "main"
  }
}