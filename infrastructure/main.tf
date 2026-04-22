terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
  required_version = ">= 1.0"

  # ──────────────────────────────────────────────
  # Backend for storing state in S3
  # ──────────────────────────────────────────────  
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "evgeny-diplom-dvops"
    key    = "infrastructure/terraform.tfstate"
    region = "ru-central1"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
}

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

locals {
  ssh_public_key = file(var.ssh_public_key_path)

  zone_to_subnet = {
    "ru-central1-a" = yandex_vpc_subnet.k8s_subnet_a.id
    "ru-central1-b" = yandex_vpc_subnet.k8s_subnet_b.id
    "ru-central1-d" = yandex_vpc_subnet.k8s_subnet_d.id
  }
}