resource "kubernetes_namespace" "flux" {
  metadata {
    name = var.namespace
  }
}

resource "tls_private_key" "flux" {
  algorithm = "ED25519"
}

resource "kubernetes_secret" "flux_git_ssh" {
  metadata {
    name      = "flux-system"
    namespace = var.namespace
  }

  data = {
    identity = base64encode(tls_private_key.flux.private_key_pem)
  }

  type = "Opaque"
}

resource "null_resource" "register_flux_key_in_gitea" {
  provisioner "local-exec" {
    command = <<EOT
curl -s -X POST ${var.gitea_url}/api/v1/user/keys \
  -u ${var.gitea_user}:${var.gitea_pass} \
  -H "Content-Type: application/json" \
  -d '{
    "title": "flux-access",
    "key": "${tls_private_key.flux.public_key_openssh}"
  }'
EOT
  }

  triggers = {
    pubkey = tls_private_key.flux.public_key_openssh
  }
}

# resource "null_resource" "create_flux_repo_in_gitea" {
#   provisioner "local-exec" {
#     command = <<EOT
# curl -s -X POST ${var.gitea_url}/api/v1/user/repos \
#   -u ${var.gitea_user}:${var.gitea_pass} \
#   -H "Content-Type: application/json" \
#   -d '{
#     "name": "${var.gitea_repo}",
#     "private": true,
#     "auto_init": true
#   }'
# EOT
#   }
#
#   triggers = {
#     repo_name = var.gitea_repo
#   }
#
#   depends_on = [null_resource.register_flux_key_in_gitea]
# }

# resource "kubernetes_config_map" "flux_known_hosts" {
#   metadata {
#     name      = "flux-known-hosts"
#     namespace = var.namespace
#   }
#
#   data = {
#     known_hosts = var.gitea_known_hosts
#   }
# }

# resource "null_resource" "wait_known_hosts" {
#   depends_on = [kubernetes_config_map.flux_known_hosts]
#
#   provisioner "local-exec" {
#     command = "sleep 5"
#   }
# }


resource "flux_bootstrap_git" "flux" {
  depends_on = [
    kubernetes_secret.flux_git_ssh,
#     null_resource.create_flux_repo_in_gitea,
    null_resource.register_flux_key_in_gitea,
#     null_resource.wait_known_hosts
  ]
  embedded_manifests = true
  path   = "clusters/${var.flux_cluster_path}"


}