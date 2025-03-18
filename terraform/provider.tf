provider "oci" {
    user_ocid           = var.user_id
    fingerprint         = var.fingerprint
    tenancy_ocid        = var.tenancy_id
    region              = var.region
    private_key         = file(var.path_to_private_key)
}

terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = ">=4.67.3"
    }
  }
  required_version = ">= 1.11.0"

  backend "s3" {
    bucket = "opencost-terraform-state-store"
    region = "us-ashburn-1"
    key = "tf.tfstate"
    skip_region_validation = true
    skip_credentials_validation = true
    skip_requesting_account_id = true
    use_path_style = true
    skip_s3_checksum = true
    skip_metadata_api_check = true
    endpoints = {
      s3 = "https://idupkgm3j7ue.compat.objectstorage.us-ashburn-1.oraclecloud.com"
    }
  }
}

provider "kubernetes" {
    config_path = local_file.kubeconfig.filename
}

provider "helm" {
    kubernetes {
        config_path = local_file.kubeconfig.filename
    }
}