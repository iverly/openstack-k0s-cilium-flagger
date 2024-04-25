terraform {
  required_version = ">= 0.14.0"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.6.1"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.26.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">=2.9.0"
    }
  }
}
