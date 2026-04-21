output "bucket_name" {
  description = "Name S3 bucket"
  value       = yandex_storage_bucket.tf_state.bucket
}

output "access_key" {
  description = "Access key для S3 bucket"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  sensitive   = true
}

output "secret_key" {
  description = "Secret key для S3 bucket"
  value       = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  sensitive   = true
}

output "registry_key" {
  description = "id registry yandex cloude"
  value = yandex_container_registry.registry-docker.id
}