# ──────────────────────────────────────────────
# Yandex Cloud
# ──────────────────────────────────────────────

variable "yc_token" {
  default   = "TOKEN yandex cloud"
  sensitive = true
}

variable "cloud_id" {
  description = "ID cloude yandex cloud"
  sensitive   = true
}

variable "folder_id" {
  description = "ID folder yandex cloud"
  sensitive   = true
}

variable "service_account_id" {
  description = "ID service account yandex cloud"
}

variable "aws_key" {
  description = "AWS access key for S3 backend"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key for S3 backet"
  type        = string
  sensitive   = true
}

# ──────────────────────────────────────────────
# Project
# ──────────────────────────────────────────────

variable "project_name" {
  description = "Name project cloud"
  type        = string
  default     = "k8s-project"
}

variable "image_family" {
  description = "name image"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_user" {
  description = "SSH username for VMs"
  type        = string
  default     = "ubuntu"
}

# ──────────────────────────────────────────────
# Claster (master)
# ──────────────────────────────────────────────

variable "master_count" {
  description = "Number master nodes"
  type        = number
  default     = 1
}

variable "master_cpu" {
  description = "CPU cores for master nodes"
  type        = number
  default     = 2
}

variable "master_memory" {
  description = "RAM for master nades"
  type        = number
  default     = 2
}

variable "master_disk_size" {
  description = "Disk size for master nodes"
  type        = number
  default     = 20
}

variable "master_disk_type" {
  description = "master disk type"
  type        = string
  default     = "network-hdd"
}

variable "master_core_fraction" {
  description = "Cores fraction for master nodes"
  type        = number
  default     = 20
}

# ──────────────────────────────────────────────
# Claster (worker)
# ──────────────────────────────────────────────

variable "worker_count" {
  description = "Namber worker nodes"
  type        = number
  default     = 2
}

variable "worker_cpu" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 2
}

variable "worker_memory" {
  description = "RAM for worker nodes"
  type        = number
  default     = 2
}

variable "worker_disk_size" {
  description = "Disk size for worker nodes"
  type        = number
  default     = 20
}

variable "worker_disk_type" {
  description = "worker disk type"
  type        = string
  default     = "network-hdd"
}

variable "worker_core_fraction" {
  description = "Cores fraction for worker nodes"
  type        = number
  default     = 20
}


# ──────────────────────────────────────────────
# Zones
# ──────────────────────────────────────────────

variable "zones" {
  description = "Zones for nodes"
  type        = list(string)
  default     = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}