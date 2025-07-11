locals {
  git_ssh_url = "ssh://git@${replace(replace(var.gitea_url, "https://", ""), "http://", "")}:${var.gitea_ssh_port}/${var.gitea_repo}.git"

}