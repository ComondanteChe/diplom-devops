variable "service_account_id" {
  description = "ID service account"
  type        = string
}

variable "bucket_name" {
  description = "Имя S3 bucket для хранения Terraform state (должно быть уникальным)"
  type        = string
  default     = "terraform-state-k8s-project"
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token (or IAM token)"
  type        = string
  sensitive   = true
}

variable "cloud_id" {
  description = "Yandex Cloud cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Cloud folder ID"
  type        = string
}

variable "name-registry" {
  description = "Name registry yandex cloude"
  type = string
  default = "registry-docker"
}

