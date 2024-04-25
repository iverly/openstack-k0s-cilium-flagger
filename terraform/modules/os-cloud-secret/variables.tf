variable "name" {
  description = "The name of the application credential"
}

variable "openstack_auth_url" {
  description = "URL of the OpenStack authentication endpoint"
}

variable "network_external_id" {
  description = "ID of the external network"
}

variable "network_internal_subnet_id" {
  description = "ID of the internal subnet"
}
