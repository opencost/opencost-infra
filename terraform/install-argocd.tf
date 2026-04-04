resource "helm_release" "argo_cd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "9.0.2"
  namespace        = "argo"
  create_namespace = true
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
}

resource "kubernetes_cluster_role_binding_v1" "argocd_cluster_admin" {
  depends_on = [helm_release.argo_cd]

  metadata {
    name = "argocd-application-controller-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-application-controller"
    namespace = "argo"
  }
}

resource "kubernetes_cluster_role_binding_v1" "envoy_gateway_cluster_admin" {
  metadata {
    name = "envoy-gateway-cluster-admin"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }

  subject {
    kind      = "ServiceAccount"
    name      = "envoy-gateway"
    namespace = "envoy-gateway-system"
  }
}
