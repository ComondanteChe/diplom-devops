# ──────────────────────────────────────────────
# KMS key
# ──────────────────────────────────────────────
resource "yandex_kms_symmetric_key" "bucket_key" {
  name = "bucket-encryption-key"
  description = "KMS key for S3 bucket encryption"
  default_algorithm = "AES_256"
  rotation_period = "8760h"
  folder_id = var.folder_id
}