resource "helm_release" "this" {
  name = var.name

  repository = "https://fluxcd-community.github.io/helm-charts"
  chart      = "flux2-sync"
  version    = "1.8.2"

  namespace = var.namespace
  wait      = true

  ## Git Repository
  set {
    name  = "gitRepository.spec.url"
    value = var.git_url
  }

  set {
    name  = "gitRepository.spec.interval"
    value = "5m"
  }

  set {
    name  = "gitRepository.spec.ref.branch"
    value = "main"
  }

  ## Kustomization Repository
  set {
    name  = "kustomization.spec.interval"
    value = "5m"
  }

  set {
    name  = "kustomization.spec.prune"
    value = "true"
  }

  set {
    name  = "kustomization.spec.wait"
    value = "true"
  }

  set {
    name  = "kustomization.spec.path"
    value = var.path
  }
}
