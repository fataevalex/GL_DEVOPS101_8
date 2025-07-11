terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.11.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.10.0"
    }

    flux = {
      source = "fluxcd/flux"
      version = ">=1.6.3"
    }

    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
  }

  required_version = ">= 1.3.0"
}

provider "kubernetes" {
  config_path = var.kubeconfig != "" ? var.kubeconfig : null
}


provider "flux" {

  kubernetes  = {
    config_path = var.kubeconfig != "" ? var.kubeconfig : null
  }
  git  = {
#     url    = local.git_ssh_url
    url    = "${var.gitea_url}/${var.gitea_repo}"

    http={
      username = var.gitea_user,
      password = var.gitea_pass
    }
    branch = "main"
#     ssh = {
#       username    = "git"
#       private_key = tls_private_key.flux.private_key_pem
#       key  = "identity"
#       known_hosts = var.gitea_known_hosts
#
#     }
  }

}

