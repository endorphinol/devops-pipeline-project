variable "zone" {
  description = "Зона доступности"
  type        = string
  default     = "ru-central1-e"
}

variable "service_account_master" {
  type = string
}

variable "service_account_node" {
  type = string
}
