output "gitea_url" {
  value       = var.gitea_url
  description = "Gitea web interface"
}

output "flux_repo" {
  value = "${var.gitea_url}/${var.gitea_repo}.git"
}

output "flux_ssh_public_key" {
  value       = tls_private_key.flux.public_key_openssh
  description = "Публичный SSH-ключ для добавления в Gitea"
}
