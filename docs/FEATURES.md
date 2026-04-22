# Особенности и ограничения проекта

Этот файл описывает нюансы, которые важно знать при использовании и сопровождении проекта.

---

## Прерываемые ВМ (Preemptible)

**Что это:** Yandex Cloud принудительно останавливает прерываемые ВМ раз в 24 часа.

**Последствия:**
- IP адреса воркеров меняются при каждом перезапуске
- Мастер имеет **зарезервированный статический IP** — он не меняется
- После перезапуска ВМ сами поднимаются (Kubernetes перезапускает поды автоматически)

**Что нужно делать при смене IP воркеров:** ничего — трафик идёт через мастер, воркеры регистрируются в кластере по внутреннему IP.

**Если пересоздаётся вся инфраструктура** (новый `terraform apply` после `destroy`):
1. Мастер получит новый статический IP (старый освобождается)
2. Обновить `deploy.env`: `CLUSTER_HOST=<новый_ip>.nip.io`
3. Обновить секрет `KUBE_CONFIG` в GitHub (см. ниже)
4. Перенакатить мониторинг: `./monitoring/deploy-monitoring.sh`

---

## Обновление kubeconfig в GitHub

После пересоздания кластера сертификаты меняются — старый `KUBE_CONFIG` перестаёт работать.

```bash
# Получить новый kubeconfig с мастера
scp ubuntu@<MASTER_IP>:~/.kube/config ~/.kube/config

# Закодировать в base64 и обновить секрет вручную в GitHub:
# Settings → Secrets and variables → Actions → KUBE_CONFIG → Update secret
cat ~/.kube/config | base64 -w 0
```

---

## Сеть: IPIP протокол и Calico

Calico использует IPIP туннель (IP protocol 4) для маршрутизации трафика между подами на разных нодах.

**Важно:** Security Group должна разрешать **ANY** (не только TCP) для правила `self_security_group`:

```hcl
# infrastructure/security.tf
ingress {
  protocol          = "ANY"   # ← обязательно ANY, не TCP
  predefined_target = "self_security_group"
}
```

Если поды на разных нодах не видят друг друга — это первое что нужно проверить.

---

## Terraform: зеркало провайдеров

Официальный Terraform Registry (`registry.terraform.io`) заблокирован. Все провайдеры устанавливаются через зеркало Yandex:

```hcl
# ~/.terraformrc (и в atlantis/atlantis.yaml для Atlantis)
provider_installation {
  network_mirror {
    url = "https://terraform-mirror.yandexcloud.net/"
  }
}
```

**Для локального запуска** убедись что `~/.terraformrc` настроен так же, как в примере выше.

---

## Terraform State в S3

Стейт хранится в Yandex Object Storage:

| Модуль | Бакет | Ключ |
|---|---|---|
| bootstrap | `evgeny-diplom-dvops` | `bootstrap/terraform.tfstate` |
| infrastructure | `evgeny-diplom-dvops` | `infrastructure/terraform.tfstate` |

**Особенности:**
- Бакет создаётся модулем `bootstrap` — его нужно применить первым
- Стейт зашифрован через KMS ключ
- Включено версионирование — можно откатиться к предыдущей версии стейта
- `terraform.tfvars` никогда не коммитится (в `.gitignore`)

---

## DNS: nip.io

Домен не зарегистрирован — используется бесплатный сервис `nip.io`.

**Принцип работы:** `111.88.240.142.nip.io` → резолвится в `111.88.240.142`.

**Ограничения:**
- Нет HTTPS (нет сертификата)
- Зависит от внешнего сервиса nip.io
- При смене IP мастера нужно менять `CLUSTER_HOST` в `deploy.env`

---

## IAM токены для Container Registry

Yandex IAM токены живут **12 часов**. CI/CD получает свежий токен при каждом запуске через OAuth токен из секрета `CI_CD_DIPLOM`.

**OAuth токен** (секрет `CI_CD_DIPLOM`) — долгоживущий, но его нужно периодически обновлять в Yandex Cloud консоли если истечёт.

---

## local-path-provisioner

Стандартного StorageClass в kubeadm кластере нет. Используется `local-path-provisioner` от Rancher.

**Важно:** устанавливается **до** `kube-prometheus-stack` — иначе PVC зависнут в `Pending` и Helm будет ждать вечно.

В скрипте `deploy-monitoring.sh` это учтено — `local-path-provisioner` идёт первым шагом.

**Ограничение:** тома создаются локально на ноде. Если под переедет на другую ноду — данные потеряются. Для production нужен распределённый storage (Longhorn, Ceph и т.д.).

---

## Atlantis

**Требования для работы:**
1. GitHub webhook настроен на `http://<IP>:32080/atlantis`
2. Секрет `atlantis-secrets` создан в namespace `atlantis`
3. PR должен быть одобрен (`approved`) перед `atlantis apply`

**Terraform через Atlantis** запускается с теми же переменными что в `atlantis-env` ConfigMap — при смене `cloud_id`, `folder_id` нужно обновить ConfigMap и перезапустить под.

---

## Ресурсы и лимиты

Все ВМ используют минимальные ресурсы (20% CPU fraction) для экономии:

| Нода | CPU | RAM | Disk |
|---|---|---|---|
| master-1 | 2 core / 20% | 2 GB | 20 GB HDD |
| worker-1,2 | 2 core / 20% | 2 GB | 20 GB HDD |

При высокой нагрузке поды могут получать `CPU throttling`. Увеличить можно через `variables.tf`.
