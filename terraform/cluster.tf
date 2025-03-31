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

  # Install the prerequisites for the DCGM exporter
  node_metadata = {
    user_data = base64encode(<<-EOF
      #cloud-config
      runcmd:
        - |
          #!/bin/bash

          echo "running script"
          LOGFILE="/var/log/install_step.log"

          get_step() {
              if [ -f "$LOGFILE" ]; then
                  cat "$LOGFILE"
              else
                  echo "0"
              fi
          }

          set_step() {
              echo "$1" | sudo tee "$LOGFILE" > /dev/null
          }

          CURRENT_STEP=$(get_step)
          echo "Current Step is: $CURRENT_STEP"

          # Get default kernel version and check if it's already Oracle 8.10
          if [ "$CURRENT_STEP" -lt 1 ]; then
              echo "Step 1: Getting available kernels..."
              
              # Capture the default kernel path
              DEFAULT_KERNEL=$(sudo grubby --default-kernel)
              
              # Check if the default kernel is Oracle 8.10
              if echo "$DEFAULT_KERNEL" | grep -q "el8_10"; then
                  echo "Oracle 8.10 kernel is already the default kernel. Skipping steps 1-3."
                  # Skip steps 1-3 and move to Step 4
                  set_step 4
                  echo "Step 1-3 skipped. Continuing with Step 4."
                  exit 0
              else
                  # Proceed with steps 1-3 if the default kernel is not Oracle 8.10
                  echo "Oracle 8.10 kernel is not the default kernel. Proceeding with kernel selection."
                  
                  # Get available kernels
                  sudo grubby --default-kernel
                  sudo grubby --info=ALL | grep ^kernel
                  set_step 1
                  echo "Step 1 complete."
                  
                  # Select and set the default Oracle 8.10 kernel
                  echo "Step 2: Selecting and setting default Oracle 8.10 kernel..."
                  KERNEL_LIST=$(sudo grubby --info=ALL | grep ^kernel | sed 's/.*=//')
                  ORACLE_KERNEL=$(echo "$KERNEL_LIST" | grep -E "el8_10" | sort -V | tail -n 1)
                  ORACLE_KERNEL=$(echo "$ORACLE_KERNEL" | sed 's/"//g')

                  if [ -z "$ORACLE_KERNEL" ]; then
                      echo "Error: No Oracle 8.10 kernel found!"
                      exit 1
                  fi

                  echo "Using kernel: $ORACLE_KERNEL"

                  # Set the selected kernel as the default
                  sudo grubby --set-default "$ORACLE_KERNEL"
                  uname -r
                  set_step 2
                  echo "Step 2 complete. Rebooting..."
                  sudo rm /var/lib/cloud/instance/sem/config_scripts_user
                  sudo reboot now
                  exit
              fi
          fi

          # Verify new kernel after reboot (Step 3)
          if [ "$CURRENT_STEP" -lt 3 ]; then
              echo "Step 3: Verifying kernel after reboot..."
              uname -r
              set_step 3
              echo "Step 3 complete."
          fi

          # Install kernel development packages (Step 4)
          if [ "$CURRENT_STEP" -lt 4 ]; then
              echo "Step 4: Installing kernel development packages..."
              sudo dnf install -y kernel-devel-$(uname -r) kernel-headers
              set_step 4
              echo "Step 4 complete."
          fi

          # Enable CodeReady repository (Step 5)
          if [ "$CURRENT_STEP" -lt 5 ]; then
              echo "Step 5: Enabling CodeReady repository..."
              sudo dnf config-manager --set-enabled ol8_codeready_builder
              set_step 5
              echo "Step 5 complete."
          fi

          # Install EPEL releases (Step 6)
          if [ "$CURRENT_STEP" -lt 6 ]; then
              echo "Step 6: Installing Oracle EPEL release..."
              sudo dnf install -y oracle-epel-release-8
              sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
              set_step 6
              echo "Step 6 complete."
          fi

          # Add NVIDIA CUDA repository (Step 7)
          if [ "$CURRENT_STEP" -lt 7 ]; then
              echo "Step 7: Adding NVIDIA CUDA repository..."
              sudo dnf config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo
              set_step 7
              echo "Step 7 complete."
          fi

          # Clean DNF cache (Step 8)
          if [ "$CURRENT_STEP" -lt 8 ]; then
              echo "Step 8: Cleaning DNF cache..."
              sudo dnf clean all
              set_step 8
              echo "Step 8 complete."
          fi

          # Install NVIDIA driver (latest DKMS) (Step 9)
          if [ "$CURRENT_STEP" -lt 9 ]; then
              echo "Step 9: Installing NVIDIA driver..."
              sudo dnf module install -y nvidia-driver:latest-dkms
              sudo dnf install -y nvidia-driver-cuda kmod-nvidia-latest-dkms
              set_step 9
              echo "Step 9 complete. Rebooting..."
              sudo rm /var/lib/cloud/instance/sem/config_scripts_user
              sudo reboot now
              exit
          fi

          # Clean DNF cache again (Step 10)
          if [ "$CURRENT_STEP" -lt 10 ]; then
              echo "Step 10: Cleaning DNF cache..."
              sudo dnf clean expire-cache
              set_step 10
              echo "Step 10 complete."
          fi

          # Determine CUDA version (Step 11)
          if [ "$CURRENT_STEP" -lt 11 ]; then
              echo "Step 11: Determining CUDA version..."
              CUDA_VERSION=$(nvidia-smi | sed -E -n 's/.*CUDA Version: ([0-9]+)[.].*/\1/p')
              set_step 11
              echo "CUDA Version detected: $CUDA_VERSION"
              echo "Step 11 complete."
          fi

          # Install Data Center GPU Manager (Step 12)
          if [ "$CURRENT_STEP" -lt 12 ]; then
              echo "Step 12: Installing Data Center GPU Manager..."
              sudo dnf install -y --assumeyes --setopt=install_weak_deps=True datacenter-gpu-manager-4-cuda$${CUDA_VERSION}
              set_step 12
              echo "Step 12 complete."
          fi

          # Enable NVIDIA DCGM service (Step 13)
          if [ "$CURRENT_STEP" -lt 13 ]; then
              echo "Step 13: Enabling NVIDIA DCGM service..."
              sudo systemctl --now enable nvidia-dcgm
              set_step 13
              echo "Step 13 complete. Installation finished!"
          fi

          # Configure nvidia-container-toolkit repository (Step 14)
          if [ "$CURRENT_STEP" -lt 14 ]; then
              echo "Step 14: Configuring nvidia-containerd-toolkit repository..."

              distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
              curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
              curl -s -L https://nvidia.github.io/libnvidia-container/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

              set_step 14
              echo "Step 14 complete."
          fi

          # Install nvidia-container-toolkit (Step 15)
          if [ "$CURRENT_STEP" -lt 15 ]; then
              echo "Step 15: Installing NVIDIA Container Toolkit..."
              
              sudo dnf install -y nvidia-container-toolkit
              sudo systemctl restart containerd

              set_step 15
              echo "Step 15 complete."
          fi          

          echo "All steps completed successfully!"
          nvidia-smi

        - 'sudo curl --fail -H "Authorization: Bearer Oracle" -L0 http://169.254.169.254/opc/v2/instance/metadata/oke_init_script | base64 --decode >/var/run/oke-init.sh && bash /var/run/oke-init.sh'
    EOF
    )
  }
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