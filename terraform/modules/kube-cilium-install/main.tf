resource "helm_release" "this" {
  name = "cilium"

  repository = "https://helm.cilium.io"
  chart      = "cilium"
  version    = "1.15.4"

  namespace = "kube-system"
  wait      = true

  # replace kube-proxy
  set {
    name  = "kubeProxyReplacement"
    value = "true"
  }

  # use kubernetes mode for IPAM
  set {
    name  = "ipam.mode"
    value = "kubernetes"
  }

  # enable hubble
  set {
    name  = "hubble.relay.enabled"
    value = "true"
  }

  set {
    name  = "hubble.ui.enabled"
    value = "true"
  }

  # disable l7 proxy since istio will handle it
  set {
    name  = "l7Proxy"
    value = "false"
  }

  # set mandatory settings to work with istio
  set {
    name  = "socketLB.hostNamespaceOnly"
    value = "true"
  }

  set {
    name  = "cni.exclusive"
    value = "false"
  }
}
