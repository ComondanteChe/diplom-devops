# diplom-devops

Дипломный проект: production-ready инфраструктура на Yandex Cloud с Kubernetes, мониторингом и GitOps.

## Архитектура

```
                        GitHub
                           │
              ┌────────────┴────────────┐
              │ Push nginx/**           │ Pull Request (*.tf)
              ▼                         ▼
     GitHub Actions CI/CD          Atlantis (GitOps)
              │                         │
      Build & Push image           terraform plan/apply
              │                         │
              └────────────┬────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   Yandex Cloud         │
              │                        │
              │  Object Storage (S3)   │  ← Terraform state
              │  Container Registry    │  ← Docker images
              │                        │
              │  ┌──────────────────┐  │
              │  │  VPC Network     │  │
              │  │                  │  │
              │  │  master-1 ●──────┼──┼── Static IP (111.88.240.142)
              │  │  worker-1 ○      │  │   Preemptible VM
              │  │  worker-2 ○      │  │   Preemptible VM
              │  └──────────────────┘  │
              └────────────────────────┘
                           │
                    Kubernetes (kubeadm)
                           │
          ┌────────────────┼────────────────┐
          │                │                │
          ▼                ▼                ▼
    ingress-nginx     monitoring        atlantis
    (NodePort 32080)  namespace         namespace
          │                │
          ├── /app     Prometheus
          ├── /grafana  Grafana
          ├── /prometheus Alertmanager
          ├── /alertmanager
          └── /atlantis

    Calico CNI (IPIP mode) — связь между нодами
    local-path-provisioner — StorageClass для PVC
```

## Стек технологий

| Слой | Технология |
|---|---|
| Облако | Yandex Cloud |
| IaC | Terraform v1.14.8 |
| Состояние Terraform | Yandex Object Storage (S3) + KMS шифрование |
| Образы | Yandex Container Registry |
| ВМ | Ubuntu 22.04 LTS, прерываемые |
| Kubernetes | kubeadm v1.28.0 |
| CNI | Calico v3.25 |
| Ingress | ingress-nginx (NodePort) |
| Storage | local-path-provisioner |
| Мониторинг | kube-prometheus-stack (Prometheus + Grafana + Alertmanager) |
| Приложение | Nginx, упакован в Helm чарт |
| CI/CD | GitHub Actions |
| GitOps IaC | Atlantis |
| DNS | nip.io (бесплатный wildcard DNS по IP) |

## Быстрый старт

```bash
# 1. Создать S3 бакет и реестр (один раз)
cd bootstrap
cp terraform.tfvars.example terraform.tfvars  # заполнить своими значениями
terraform init -backend-config=backend.hcl
terraform apply

# 2. Поднять инфраструктуру (ВМ + сеть + security groups)
cd ../infrastructure
cp terraform.tfvars.example terraform.tfvars  # заполнить своими значениями
terraform init
terraform apply

# 3. Настроить Kubernetes через Ansible
cd ansible
ansible-playbook -i inventory/hosts.ini site.yml

# 4. Получить kubeconfig
scp ubuntu@<MASTER_IP>:~/.kube/config ~/.kube/config

# 5. Настроить переменные деплоя
cd ..
cp deploy.env.example deploy.env
# Вписать IP мастера: terraform output ingress_nip_io

# 6. Задеплоить мониторинг и приложение
./monitoring/deploy-monitoring.sh
helm upgrade --install nginx-app ./helm/nginx-app \
  --namespace app --create-namespace \
  --set ingress.host=$(grep CLUSTER_HOST deploy.env | cut -d= -f2)
```

## Доступ к сервисам

После деплоя все сервисы доступны через ingress на порту `32080`:

| Сервис | URL |
|---|---|
| Приложение | `http://<IP>.nip.io:32080/app` |
| Grafana | `http://<IP>.nip.io:32080/grafana` |
| Prometheus | `http://<IP>.nip.io:32080/prometheus` |
| Alertmanager | `http://<IP>.nip.io:32080/alertmanager` |
| Atlantis | `http://<IP>.nip.io:32080/atlantis` |

IP мастера: `terraform output ingress_nip_io` из директории `infrastructure/`.

## Важные особенности

> Подробнее — в [docs/FEATURES.md](docs/FEATURES.md)

- **Прерываемые ВМ** перезапускаются раз в сутки. IP воркеров меняется, IP мастера — статический.
- **После пересоздания кластера** нужно обновить секрет `KUBE_CONFIG` в GitHub.
- **IPIP протокол** должен быть разрешён в Security Group для Calico (правило `ANY` для `self_security_group`).
- **Terraform провайдеры** устанавливаются через зеркало `terraform-mirror.yandexcloud.net`.

## Структура репозитория

```
├── bootstrap/          # S3 бакет, KMS ключ, Container Registry
├── infrastructure/     # ВМ, сеть, Security Groups + Ansible
│   └── ansible/        # Роли: common, k8s_master, k8s_worker
├── helm/nginx-app/     # Helm чарт приложения
├── monitoring/         # kube-prometheus-stack, ingress-nginx
├── atlantis/           # K8s манифесты для Atlantis
├── nginx/              # Dockerfile и исходники приложения
├── .github/workflows/  # CI/CD пайплайн
├── deploy.env          # Переменные деплоя (не в git)
├── deploy.env.example  # Шаблон переменных
├── deploy.sh           # Единая точка деплоя K8s манифестов
└── docs/               # Документация
```

## Документация

- [Шпаргалка команд](docs/COMMANDS.md)
- [Особенности и ограничения](docs/FEATURES.md)
- [Bootstrap: S3 и реестр](docs/01-bootstrap.md)
- [Инфраструктура: ВМ и K8s](docs/02-infrastructure.md)
- [Мониторинг](docs/03-monitoring.md)
- [Приложение и CI/CD](docs/04-app.md)
- [Atlantis: GitOps для Terraform](docs/05-atlantis.md)
