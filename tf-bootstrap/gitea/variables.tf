variable "namespace" {
  default = "flux-system"
}

variable "gitea_namespace" {
  default = "gitea"
}

variable "gitea_repo" {
  default = "flux-repo"
}

variable "gitea_user" {
  description = "Имя служебного пользователя Gitea, созданного вручную через Web UI"
  default     = "flux-bot"
}

variable "gitea_pass" {
  description = "Пароль служебного пользователя Gitea"
  default     = "bot-password"
}

variable "kubeconfig" {
  type        = string
  description = "Путь к kubeconfig. По умолчанию использует KUBECONFIG или ~/.kube/config"
  default     = ""
}

variable "gitea_url" {
  type        = string
  description = "Базовый URL Gitea (например, https://gitea.example.com)"
  default     = "https://gitea.fataev.in.ua"
}

variable "flux_cluster_path" {
  default = "kind-kind"
}
variable "gitea_ssh_port" {
  default = 22
}

variable "gitea_known_hosts" {
  type        = string
  description = "SSH known_hosts строка для подключения к Gitea по SSH"
}