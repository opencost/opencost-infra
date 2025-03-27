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
  create_bastion        = false

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

resource "oci_containerengine_node_pool" "gpu_node_pool" {
  cluster_id         = module.oke.cluster_id
  compartment_id     = var.compartment_id
  kubernetes_version = var.kubernetes_version
  name              = var.gpu_node_pool_name
  node_shape        = var.gpu_node_shape

  node_config_details {
    placement_configs {
      availability_domain = var.availability_domain
      subnet_id          = module.oke.worker_subnet_id
    }
    size = 1
    nsg_ids = [module.oke.worker_nsg_id]
  }

  node_source_details {
    image_id = var.image_id
    source_type = "IMAGE"
  }

  ### WIP Testing
  node_metadata = {
    user_data = base64encode(<<-EOF
      #cloud-config
      runcmd:
        - sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
        - sudo dnf config-manager --set-enable ol8_developer_EPEL
        - sudo dnf install -y gcc make kernel-headers kernel-devel oracle-epel-release-el8 epel-release dkms
        - sudo dnf module install -y nvidia-driver:latest-dkms
        - sudo dnf install -y nvidia-driver-cuda
        - sudo dnf clean expire-cache
        - sudo curl --fail -H "Authorization: Bearer Oracle" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh bash /var/run/oke-init.sh
    EOF
    )
  }
  ### WIP Testing End
}

# Retrieves the kubeconfig file content for the specified OCI Container Engine for Kubernetes (OKE) cluster
data "oci_containerengine_cluster_kube_config" "opencost_cluster_config" {
  cluster_id = module.oke.cluster_id
}

# Saves the retrieved kubeconfig content to a local file named "kubeconfig"
# This file is not committed to GitHub
resource "local_file" "kubeconfig" {
  content  = data.oci_containerengine_cluster_kube_config.opencost_cluster_config.content
  filename = "${path.module}/kubeconfig"
  file_permission = "0600"
}