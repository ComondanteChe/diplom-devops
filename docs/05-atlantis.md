# Atlantis: GitOps для Terraform

Atlantis автоматически запускает `terraform plan/apply` при изменениях в Pull Request.

## Как это работает

```
Разработчик                    GitHub                    Atlantis
     │                            │                          │
     │── git push (*.tf) ────────►│                          │
     │── открыть PR ─────────────►│                          │
     │                            │── webhook ──────────────►│
     │                            │                          │── terraform plan
     │◄── комментарий с планом ───│◄─────────────────────────│
     │                            │                          │
     │── approve PR ─────────────►│                          │
     │── comment: atlantis apply ►│                          │
     │                            │── webhook ──────────────►│
     │                            │                          │── terraform apply
     │◄── комментарий с результатом│◄────────────────────────│
```

## Деплой Atlantis

```bash
# Создать секреты (один раз)
kubectl create namespace atlantis
kubectl create secret generic atlantis-secrets \
  --namespace=atlantis \
  --from-literal=github_token=<GITHUB_TOKEN> \
  --from-literal=github_webhook_secret=<WEBHOOK_SECRET> \
  --from-literal=yc_token=<YC_OAUTH_TOKEN> \
  --from-literal=aws_key=<S3_ACCESS_KEY> \
  --from-literal=aws_secret_key=<S3_SECRET_KEY> \
  --from-literal=ssh_public_key="$(cat ~/.ssh/id_rsa.pub)"

# Применить манифест
kubectl apply -f atlantis/atlantis.yaml
```

## Настройка GitHub Webhook

В репозитории: **Settings → Webhooks → Add webhook**

| Поле | Значение |
|---|---|
| Payload URL | `http://<IP>.nip.io:32080/atlantis` |
| Content type | `application/json` |
| Secret | `<WEBHOOK_SECRET>` |
| Events | Pull request + Issue comments |

## Команды в PR

| Команда | Действие |
|---|---|
| `atlantis plan` | Запустить terraform plan |
| `atlantis apply` | Применить (требует approved PR) |
| `atlantis plan -d infrastructure` | Plan для конкретного проекта |
| `atlantis unlock` | Снять блокировку workspace |

## Конфигурация проектов

Файл `atlantis.yaml` в корне репозитория:

```yaml
version: 3
projects:
- name: bootstrap
  dir: bootstrap
  terraform_version: v1.14.8
  autoplan:
    when_modified: ["*.tf", "*.tfvars"]

- name: infrastructure
  dir: infrastructure
  terraform_version: v1.14.8
  autoplan:
    when_modified: ["*.tf", "*.tfvars"]
```

## Переменные Terraform в Atlantis

Передаются через `ConfigMap atlantis-env` и `Secret atlantis-secrets`:

| Переменная | Источник |
|---|---|
| `TF_VAR_yc_token` | Secret |
| `TF_VAR_cloud_id` | ConfigMap |
| `TF_VAR_folder_id` | ConfigMap |
| `TF_VAR_service_account_id` | ConfigMap |
| `AWS_ACCESS_KEY_ID` | Secret (для S3 backend) |
| `AWS_SECRET_ACCESS_KEY` | Secret (для S3 backend) |

При изменении значений — обновить ConfigMap и перезапустить под:

```bash
kubectl edit configmap atlantis-env -n atlantis
kubectl rollout restart statefulset/atlantis -n atlantis
```

## Terraform через зеркало

Atlantis настроен на использование зеркала через `.terraformrc`:

```hcl
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
  }
}
```

Terraform бинарник скачивается при старте пода через `initContainer` с `hashicorp-releases.yandexcloud.net`.
