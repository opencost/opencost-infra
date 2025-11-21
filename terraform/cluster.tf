module "oke" {

  source  = "oracle-terraform-modules/oke/oci"
  version = "5.2.4"

  home_region = var.region

  region = var.region

  tenancy_id = var.tenancy_id

  # general oci parameters
  compartment_id = var.compartment_id

  # networking
  create_drg                        = false
  assign_public_ip_to_control_plane = true
  vcn_name                          = var.vcn_name

  # bastion host
  create_bastion = false

  # operator host
  create_operator            = true
  operator_upgrade           = false
  create_iam_resources       = true
  create_iam_operator_policy = "always"
  operator_install_k9s       = true

  # oke cluster options
  cluster_name                = var.cluster_name
  control_plane_is_public     = true
  control_plane_allowed_cidrs = ["0.0.0.0/0"]
  kubernetes_version          = var.kubernetes_version

  # node pools
  allow_worker_ssh_access = false
  kubeproxy_mode          = "iptables"
  worker_pool_mode        = "node-pool"
  worker_pools            = var.nodepools

  user_id = var.user_id

  providers = {
    oci      = oci
    oci.home = oci
  }
}

locals {
  worker_node_user_data = base64encode(<<-EOF
    #cloud-config
    apt:
      sources:
        oke-node: {source: 'deb [trusted=yes] https://objectstorage.us-sanjose-1.oraclecloud.com/p/45eOeErEDZqPGiymXZwpeebCNb5lnwzkcQIhtVf6iOF44eet_efdePaF7T8agNYq/n/odx-oke/b/okn-repositories-private/o/prod/ubuntu-jammy/kubernetes-1.31 stable main'}
    packages:
    - oci-oke-node-all-1.31.1
    runcmd:
    - oke bootstrap
  EOF
  )

  spot_shape_config_required = can(regex("(?i)flex", var.spot_node_shape))
}

resource "oci_containerengine_node_pool" "gpu_node_pool" {
  cluster_id         = module.oke.cluster_id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.gpu_node_pool_name
  node_shape         = var.gpu_node_shape

  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = module.oke.worker_subnet_id
    }
    size    = 1
    nsg_ids = [module.oke.worker_nsg_id]
  }

  node_source_details {
    image_id    = var.image_id
    source_type = "IMAGE"
  }

  # Install and configure Ubuntu worker node for GPU
  node_metadata = {
    user_data = local.worker_node_user_data
  }
}

resource "oci_containerengine_node_pool" "spot_node_pool" {
  cluster_id         = module.oke.cluster_id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name               = var.spot_node_pool_name
  node_shape         = var.spot_node_shape

  node_config_details {
    nsg_ids = [module.oke.worker_nsg_id]
    size    = var.spot_node_pool_size

    placement_configs {
      availability_domain = var.availability_domain
      subnet_id           = module.oke.worker_subnet_id

      preemptible_node_config {
        preemption_action {
          type                    = var.spot_preemption_action_type
          is_preserve_boot_volume = var.spot_preserve_boot_volume
        }
      }
    }
  }

  dynamic "node_shape_config" {
    for_each = local.spot_shape_config_required ? [1] : []
    content {
      ocpus         = var.spot_node_ocpus
      memory_in_gbs = var.spot_node_memory_in_gbs
    }
  }

  node_source_details {
    image_id                = var.image_id
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = tostring(var.spot_node_boot_volume_size_gbs)
  }

  node_metadata = {
    user_data = local.worker_node_user_data
  }
}

# Retrieves the kubeconfig file content for the specified OCI Container Engine for Kubernetes (OKE) cluster
data "oci_containerengine_cluster_kube_config" "opencost_cluster_config" {
  cluster_id = module.oke.cluster_id
}

# Saves the retrieved kubeconfig content to a local file named "kubeconfig"
# This file is not committed to GitHub
resource "local_file" "kubeconfig" {
  content         = data.oci_containerengine_cluster_kube_config.opencost_cluster_config.content
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}