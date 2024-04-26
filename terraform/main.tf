resource "random_id" "this" {
  byte_length = 4
}

module "keypair" {
  source = "./modules/os-keypair"

  public_key_pair_name = "k0s-${random_id.this.hex}"
  public_key_pair_path = var.public_key_pair_path
}

module "network" {
  source = "./modules/os-network"

  name                = "k0s.${random_id.this.hex}"
  cidr                = var.network_cidr
  external_network_id = var.network_external_id
  dns_servers         = var.network_dns_servers

  depends_on = [module.keypair]
}

module "security_groups" {
  source = "./modules/os-security-groups"

  cidr = var.network_cidr
}

module "control_plane" {
  source = "./modules/os-instance"
  count  = var.control_plane_number

  name      = "k0s.control-plane.${count.index}.${random_id.this.hex}"
  image_id  = var.control_plane_image_id
  flavor_id = var.control_plane_flavor_id

  public_key_pair = module.keypair.public_key_pair_name
  ssh_login_name  = var.ssh_login_name

  security_groups = [
    module.security_groups.ssh_name,
    module.security_groups.control_plane_api_name,
    module.security_groups.controller_name
  ]

  network = {
    name             = module.network.name
    floating_ip_pool = var.network_floating_ip_pool
  }

  depends_on = [module.keypair, module.network, module.security_groups]
}

module "worker" {
  source = "./modules/os-instance"
  count  = var.worker_number

  name      = "k0s.worker.${count.index}.${random_id.this.hex}"
  image_id  = var.worker_image_id
  flavor_id = var.worker_flavor_id

  public_key_pair = module.keypair.public_key_pair_name
  ssh_login_name  = var.ssh_login_name

  security_groups = [
    module.security_groups.ssh_name,
    module.security_groups.worker_name,
    module.security_groups.http_name
  ]

  network = {
    name             = module.network.name
    floating_ip_pool = var.network_floating_ip_pool
  }

  depends_on = [module.keypair, module.network, module.security_groups]
}

module "k0s_cluster" {
  source = "./modules/k0s-cluster"

  ssh_login_name = var.ssh_login_name
  hosts = concat(
    [for instance in module.control_plane : {
      role                = "controller"
      private_ip_address  = instance.access_ip_v4
      floating_ip_address = instance.floating_ip_address
    }],
    [for instance in module.worker : {
      role                = "worker"
      private_ip_address  = instance.access_ip_v4
      floating_ip_address = instance.floating_ip_address
    }]
  )

  depends_on = [module.keypair, module.network, module.security_groups, module.control_plane, module.worker]
}

locals {
  kube_config = yamldecode(module.k0s_cluster.kubeconfig)
}

provider "kubernetes" {
  host                   = local.kube_config.clusters[0].cluster.server
  cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
  client_certificate     = base64decode(local.kube_config.users[0].user.client-certificate-data)
  client_key             = base64decode(local.kube_config.users[0].user.client-key-data)
}

provider "helm" {
  kubernetes {
    host                   = local.kube_config.clusters[0].cluster.server
    cluster_ca_certificate = base64decode(local.kube_config.clusters[0].cluster.certificate-authority-data)
    client_certificate     = base64decode(local.kube_config.users[0].user.client-certificate-data)
    client_key             = base64decode(local.kube_config.users[0].user.client-key-data)
  }
}

module "os_cloud_secret" {
  source = "./modules/os-cloud-secret"

  name = "k0s.${random_id.this.hex}"

  openstack_auth_url         = var.openstack_auth_url
  network_external_id        = var.network_external_id
  network_internal_subnet_id = module.network.subnet_id

  depends_on = [module.k0s_cluster]
}

module "create_namespaces" {
  source = "./modules/kube-create-namespaces"

  depends_on = [module.k0s_cluster]
}

module "cilium_install" {
  source = "./modules/kube-cilium-install"

  depends_on = [module.k0s_cluster, module.create_namespaces]
}

module "flux_install" {
  source = "./modules/kube-flux-install"

  depends_on = [module.k0s_cluster, module.create_namespaces, module.cilium_install]
}

module "flux_sync" {
  source = "./modules/kube-flux-sync"

  name      = "openstack-k0s-cilium-istio-kratos"
  path      = "cluster"
  namespace = "flux-system"
  git_url   = "https://github.com/iverly/openstack-k0s-cilium-istio-kratos"

  depends_on = [module.k0s_cluster, module.create_namespaces, module.cilium_install, module.flux_install]
}
