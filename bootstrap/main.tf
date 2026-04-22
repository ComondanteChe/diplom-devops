terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.100"
    }
  }
  required_version = ">= 1.0"

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "evgeny-diplom-dvops"
    key    = "bootstrap/terraform.tfstate"
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

# ──────────────────────────────────────────────
# Storage bucket
# ──────────────────────────────────────────────
resource "yandex_storage_bucket" "tf_state" {
  bucket     = var.bucket_name
  folder_id = var.folder_id
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.bucket_key.id
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  force_destroy = false

  anonymous_access_flags {
    read = false
    list = false
  }
}

resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = var.service_account_id
  description        = "Static access key for Terraform state bucket"
}