# Outputs the file path of the kubeconfig file for the cluster
output "kubeconfig" {
  value = local_file.kubeconfig.filename
  description = "Path to the generated kubeconfig file"
}