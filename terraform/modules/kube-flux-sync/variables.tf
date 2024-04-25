variable "name" {
  description = "The name of the Helm release"
  type        = string
}

variable "git_url" {
  description = "The URL of the Git repository"
  type        = string
}

variable "namespace" {
  description = "The namespace to install the Helm release"
  type        = string
}

variable "path" {
  description = "The path to the kustomization files"
  type        = string
}
