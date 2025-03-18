resource "helm_release" "argo_cd" {
    name       = "argo-cd"
    repository = "https://argoproj.github.io/argo-helm"
    chart      = "argo-cd"
    version    = "7.0.0"
    namespace = "argo"
    create_namespace = true
    set {
        name  = "server.service.type"
        value = "ClusterIP"
    }
}