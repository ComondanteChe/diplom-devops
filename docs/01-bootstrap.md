# Bootstrap: S3 бакет и Container Registry

Модуль `bootstrap` создаётся **один раз** перед всей остальной инфраструктурой.

## Что создаётся

- **S3 бакет**  — хранение Terraform state
- **KMS ключ** — шифрование содержимого бакета
- **Static access key** — для доступа к S3 из Terraform backend
- **Container Registry** — хранение Docker образов приложения

## Порядок применения

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
# Заполнить: yc_token, cloud_id, folder_id, service_account_id, bucket_name

terraform init -backend-config=backend.hcl
terraform apply
```

## Outputs

После `terraform apply` получить ключи для S3:

```bash
terraform output -raw access_key    # → aws_key в infrastructure/terraform.tfvars
terraform output -raw secret_key    # → aws_secret_key в infrastructure/terraform.tfvars
terraform output registry_key       # → ID реестра для REGISTRY в GitHub Variables
```

## Важно

- `backend.hcl` содержит access/secret ключи для S3 — **не коммитить**
- Бакет имеет `force_destroy = false` — случайно удалить нельзя
- KMS ключ ротируется раз в год (`rotation_period = "8760h"`)
