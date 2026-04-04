# Outputs the file path of the kubeconfig file for the cluster
output "kubeconfig" {
  value       = local_sensitive_file.kubeconfig.filename
  description = "Path to the generated kubeconfig file"
}

output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.opencost.name
  description = "AKS cluster name"
}

output "resource_group_name" {
  value       = azurerm_resource_group.opencost.name
  description = "Resource group used for AKS"
}
