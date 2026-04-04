locals {
  tags = merge(
    {
      environment = var.environment
    },
    var.tags
  )

  node_resource_group_name = (
    var.node_resource_group_name != "" ? var.node_resource_group_name : null
  )
  dns_prefix = var.dns_prefix != "" ? var.dns_prefix : var.cluster_name
}

resource "azurerm_resource_group" "opencost" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "opencost" {
  name                = "${var.cluster_name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.opencost.location
  resource_group_name = azurerm_resource_group.opencost.name
  tags                = local.tags
}

resource "azurerm_subnet" "aks" {
  name                 = "${var.cluster_name}-aks"
  address_prefixes     = [var.aks_subnet_cidr]
  resource_group_name  = azurerm_resource_group.opencost.name
  virtual_network_name = azurerm_virtual_network.opencost.name

  delegation {
    name = "aks-delegation"
    service_delegation {
      name = "Microsoft.ContainerService/managedClusters"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_kubernetes_cluster" "opencost" {
  name                = var.cluster_name
  location            = azurerm_resource_group.opencost.location
  resource_group_name = azurerm_resource_group.opencost.name
  dns_prefix          = local.dns_prefix
  kubernetes_version  = var.kubernetes_version
  node_resource_group = local.node_resource_group_name

  default_node_pool {
    name                         = var.system_node_pool.name
    vm_size                      = var.system_node_pool.vm_size
    node_count                   = var.system_node_pool.count
    only_critical_addons_enabled = var.system_node_pool.only_critical_addons
    os_disk_size_gb              = var.system_node_pool.os_disk_size_gb
    orchestrator_version         = var.kubernetes_version
    max_pods                     = var.system_node_pool.max_pods
    type                         = "VirtualMachineScaleSets"
    vnet_subnet_id               = azurerm_subnet.aks.id
    zones                        = var.system_node_pool.zones
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.api_server_authorized_ranges
  }

  oidc_issuer_enabled               = var.enable_workload_identity
  workload_identity_enabled         = var.enable_workload_identity
  role_based_access_control_enabled = true

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "spot" {
  count = var.spot_node_pool.enabled ? 1 : 0

  name                  = var.spot_node_pool.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.opencost.id
  vm_size               = var.spot_node_pool.vm_size
  priority              = "Spot"
  eviction_policy       = var.spot_node_pool.eviction_policy
  spot_max_price        = var.spot_node_pool.max_price
  auto_scaling_enabled  = var.spot_node_pool.enable_auto_scaling
  min_count             = var.spot_node_pool.enable_auto_scaling ? var.spot_node_pool.min_count : null
  max_count             = var.spot_node_pool.enable_auto_scaling ? var.spot_node_pool.max_count : null
  node_count            = var.spot_node_pool.enable_auto_scaling ? null : var.spot_node_pool.count
  os_disk_size_gb       = var.spot_node_pool.os_disk_size_gb
  orchestrator_version  = var.kubernetes_version
  vnet_subnet_id        = azurerm_subnet.aks.id
  mode                  = "User"
  node_labels           = var.spot_node_pool.node_labels
  node_taints           = var.spot_node_pool.node_taints
  zones                 = var.spot_node_pool.zones
  tags                  = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "gpu" {
  count = var.gpu_node_pool.enabled ? 1 : 0

  name                  = var.gpu_node_pool.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.opencost.id
  vm_size               = var.gpu_node_pool.vm_size
  auto_scaling_enabled  = var.gpu_node_pool.enable_auto_scaling
  min_count             = var.gpu_node_pool.enable_auto_scaling ? var.gpu_node_pool.min_count : null
  max_count             = var.gpu_node_pool.enable_auto_scaling ? var.gpu_node_pool.max_count : null
  node_count            = var.gpu_node_pool.enable_auto_scaling ? null : var.gpu_node_pool.count
  os_disk_size_gb       = var.gpu_node_pool.os_disk_size_gb
  orchestrator_version  = var.kubernetes_version
  vnet_subnet_id        = azurerm_subnet.aks.id
  mode                  = "User"
  node_labels           = merge({ accelerator = "gpu" }, var.gpu_node_pool.node_labels)
  node_taints           = concat(["accelerator=gpu:NoSchedule"], var.gpu_node_pool.node_taints)
  zones                 = var.gpu_node_pool.zones
  tags                  = local.tags
}

resource "local_sensitive_file" "kubeconfig" {
  content         = azurerm_kubernetes_cluster.opencost.kube_config_raw
  filename        = "${path.module}/kubeconfig"
  file_permission = "0600"
}
