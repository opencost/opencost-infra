resource "kubernetes_manifest" "argocd_application" {
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "opencost-root-app"
      namespace = "argo"
      labels = {
        stage = "${var.environment}-app"
        app = "opencost"
      }
    #   finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {      
      project = "default"

      source = {
        repoURL        = var.argo_settings.source_repo_url
        targetRevision = var.argo_settings.target_revision
        path           = "argocd/appsets"
      }
      
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = "argo"
      }

      info = [
        {
          name = "app-apps"
          value = "${var.environment}-app"
        }
      ]
      
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions=[
          "Validate=false",
          "CreateNamespace=true",
          "PrunePropagationPolicy=foreground",
          "RespectIgnoreDifferences=true",
          "PruneLast=true",
          "ApplyOutOfSyncOnly=true"
        ]
        retry = {
          limit = 5
          backoff = {
            duration    = "50s"
            maxDuration = "300s"
            factor      = 2
          }
        }
      }
      revisionHistoryLimit = 10
    }
  }
}