# Шпаргалка команд

## Содержание

- [Terraform](#terraform)
- [Ansible](#ansible)
- [Kubernetes](#kubernetes)
- [Helm](#helm)
- [Мониторинг](#мониторинг)
- [CI/CD и реестр](#cicd-и-реестр)
- [Atlantis](#atlantis)
- [Диагностика](#диагностика)

---

## Terraform

```bash
# ── Bootstrap (первый раз) ────────────────────────────────
cd bootstrap
terraform init -backend-config=backend.hcl
terraform plan
terraform apply

# ── Infrastructure ────────────────────────────────────────
cd infrastructure
terraform init
terraform plan
terraform apply

# Применить только конкретный ресурс
terraform apply -target=yandex_compute_instance.k8s_master

# Посмотреть outputs (IP адреса, nip.io хост)
terraform output
terraform output ingress_nip_io

# Уничтожить инфраструктуру
terraform destroy

# Обновить state (если ресурс изменили вручную в облаке)
terraform refresh

# Разблокировать state (если завис)
terraform force-unlock <LOCK_ID>
```

---

## Ansible

```bash
cd infrastructure

# Полное развёртывание кластера
ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml

# Только определённые хосты
ansible-playbook -i ansible/inventory/hosts.ini ansible/site.yml --limit master

# Проверить связь с нодами
ansible -i ansible/inventory/hosts.ini all -m ping

# Посмотреть сгенерированный inventory
cat ansible/inventory/hosts.ini
```

---

## Kubernetes

```bash
# ── Получить kubeconfig с мастера ────────────────────────
scp ubuntu@<MASTER_IP>:~/.kube/config ~/.kube/config

# ── Поды ─────────────────────────────────────────────────
kubectl get pods -A                          # все поды во всех namespace
kubectl get pods -n monitoring               # поды в monitoring
kubectl get pods -n app -o wide              # с IP и нодой

# ── Логи ─────────────────────────────────────────────────
kubectl logs -n app -l app.kubernetes.io/name=nginx-app
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana --tail=50
kubectl logs -n monitoring alertmanager-kube-prometheus-alertmanager-0 -c alertmanager

# ── Exec в под ───────────────────────────────────────────
kubectl exec -it -n app <POD_NAME> -- sh

# ── Сервисы и ingress ─────────────────────────────────────
kubectl get svc -A
kubectl get ingress -A

# ── Ноды ─────────────────────────────────────────────────
kubectl get nodes -o wide
kubectl describe node worker-1

# ── Секреты ──────────────────────────────────────────────
# Обновить kubeconfig секрет в GitHub (после пересоздания кластера)
cat ~/.kube/config | base64 -w 0
# → скопировать вывод в GitHub: Settings → Secrets → KUBE_CONFIG

# Создать секрет для pull образов из Yandex Registry
IAM_TOKEN=$(yc iam create-token)
kubectl create secret docker-registry yc-registry \
  --namespace=app \
  --docker-server=cr.yandex \
  --docker-username=iam \
  --docker-password="${IAM_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

# ── PVC и Storage ─────────────────────────────────────────
kubectl get pvc -A
kubectl get storageclass
```

---

## Helm

```bash
# ── Деплой приложения ─────────────────────────────────────
source deploy.env
helm upgrade --install nginx-app ./helm/nginx-app \
  --namespace app \
  --create-namespace \
  --set ingress.host=${CLUSTER_HOST}

# Деплой с конкретным тегом образа
helm upgrade --install nginx-app ./helm/nginx-app \
  --namespace app \
  --set image.tag=v1.0.5 \
  --set ingress.host=${CLUSTER_HOST}

# ── История и откат ───────────────────────────────────────
helm history nginx-app -n app
helm rollback nginx-app 1 -n app    # откат к ревизии 1

# ── Статус и значения ─────────────────────────────────────
helm status nginx-app -n app
helm get values nginx-app -n app
helm list -A                         # все релизы

# ── Удалить релиз ─────────────────────────────────────────
helm uninstall nginx-app -n app

# ── Отладка шаблонов без деплоя ───────────────────────────
helm template nginx-app ./helm/nginx-app --set ingress.host=test.nip.io
helm lint ./helm/nginx-app
```

---

## Мониторинг

```bash
# ── Полный деплой (с нуля) ────────────────────────────────
./monitoring/deploy-monitoring.sh

# ── Только ingress-nginx ──────────────────────────────────
./monitoring/ingress-nginx.sh

# ── Применить отдельные манифесты ────────────────────────
source deploy.env && export CLUSTER_HOST INGRESS_HTTP_PORT INGRESS_HTTPS_PORT
envsubst < monitoring/monitoring-ingress.yaml | kubectl apply -f -
envsubst < monitoring/alertmanager-patch.yaml | kubectl apply -f -

# ── Статус ────────────────────────────────────────────────
kubectl get pods -n monitoring
kubectl get pods -n ingress-nginx

# ── Перезапустить Grafana ─────────────────────────────────
kubectl rollout restart deployment/kube-prometheus-stack-grafana -n monitoring

# ── Prometheus targets (из командной строки) ──────────────
kubectl port-forward -n monitoring svc/kube-prometheus-prometheus 9090:9090
# открыть http://localhost:9090/targets
```

---

## CI/CD и реестр

```bash
# ── Запустить деплой вручную (тег) ───────────────────────
git tag v1.0.5
git push origin v1.0.5

# ── Удалить тег ──────────────────────────────────────────
git tag -d v1.0.5
git push origin --delete v1.0.5

# ── Работа с Yandex Container Registry ───────────────────
# Получить IAM токен
IAM_TOKEN=$(yc iam create-token)

# Войти в реестр
echo "${IAM_TOKEN}" | docker login cr.yandex --username iam --password-stdin

# Посмотреть образы в реестре
yc container image list --repository-name <REGISTRY_ID>/nginx-app

# Собрать и запушить образ вручную
docker build -t cr.yandex/<REGISTRY_ID>/nginx-app:v1.0.5 ./nginx/
docker push cr.yandex/<REGISTRY_ID>/nginx-app:v1.0.5
```

---

## Atlantis

```bash
# Atlantis управляется через Pull Requests в GitHub
# Команды пишутся в комментариях к PR:

atlantis plan        # запустить terraform plan
atlantis apply       # применить (требует approve PR)
atlantis plan -d infrastructure   # plan для конкретного проекта
atlantis unlock      # снять блокировку

# ── Перезапуск Atlantis ───────────────────────────────────
kubectl rollout restart statefulset/atlantis -n atlantis
kubectl logs -n atlantis atlantis-0 -f

# ── Обновить ConfigMap с переменными ─────────────────────
kubectl edit configmap atlantis-env -n atlantis
kubectl rollout restart statefulset/atlantis -n atlantis
```

---

## Диагностика

```bash
# ── Поды не стартуют ──────────────────────────────────────
kubectl describe pod <POD_NAME> -n <NAMESPACE>
kubectl get events -n <NAMESPACE> --sort-by='.lastTimestamp'

# ── PVC в Pending ─────────────────────────────────────────
kubectl get pvc -A
# Проверить что local-path-provisioner запущен:
kubectl get pods -n local-path-storage

# ── 504 от ingress ────────────────────────────────────────
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=50

# ── Поды не видят друг друга (проверка Calico/IPIP) ───────
kubectl get nodes -o wide   # посмотреть на каких нодах поды
# Если поды на разных нодах — проверить Security Group:
# правило self_security_group должно быть protocol=ANY (не TCP)

# ── Atlantis не получает вебхуки ──────────────────────────
# 1. Проверить ingress:
kubectl get ingress -n atlantis
# 2. Проверить логи:
kubectl logs -n atlantis atlantis-0
# 3. Проверить вебхук в GitHub: Settings → Webhooks → Recent Deliveries

# ── Terraform state заблокирован ──────────────────────────
cd infrastructure
terraform force-unlock <LOCK_ID>

# ── Проверить сертификат kubeconfig ───────────────────────
kubectl cluster-info
# Если ошибка x509 — обновить kubeconfig (пересоздан кластер):
scp ubuntu@<MASTER_IP>:~/.kube/config ~/.kube/config
```
