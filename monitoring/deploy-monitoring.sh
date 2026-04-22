#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/.."

# ── Загрузка переменных ───────────────────────────────────
if [[ -f "${ROOT_DIR}/deploy.env" ]]; then
  source "${ROOT_DIR}/deploy.env"
else
  echo "ERROR: deploy.env not found. Скопируй deploy.env.example -> deploy.env и заполни значения."
  exit 1
fi

export CLUSTER_HOST INGRESS_HTTP_PORT INGRESS_HTTPS_PORT

# ── Вспомогательная функция ───────────────────────────────
apply() {
  echo "  apply: $(basename "$1")"
  envsubst < "$1" | kubectl apply -f -
}

# ═══════════════════════════════════════════════════════════
echo "[1/6] local-path-provisioner (StorageClass)"
# ═══════════════════════════════════════════════════════════
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
echo "  Ожидание готовности local-path-provisioner..."
kubectl rollout status deployment/local-path-provisioner \
  --namespace local-path-storage \
  --timeout=60s

# ═══════════════════════════════════════════════════════════
echo "[2/6] ingress-nginx"
# ═══════════════════════════════════════════════════════════
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update ingress-nginx

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  -f "${SCRIPT_DIR}/ingress-values.yaml"

echo "  Ожидание готовности ingress-nginx..."
kubectl rollout status deployment/ingress-nginx-controller \
  --namespace ingress-nginx \
  --timeout=120s

# ═══════════════════════════════════════════════════════════
echo "[3/6] kube-prometheus-stack"
# ═══════════════════════════════════════════════════════════
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update prometheus-community

PROM_VALUES_TMP=$(mktemp /tmp/prometheus-values.XXXXXX.yaml)
trap "rm -f ${PROM_VALUES_TMP}" EXIT

envsubst < "${SCRIPT_DIR}/prometheus-values.yaml" > "${PROM_VALUES_TMP}"

if helm status kube-prometheus-stack --namespace monitoring &>/dev/null; then
  echo "  Релиз уже установлен, пропускаем helm (поды уже запущены)"
else
  echo "  Первичная установка..."
  helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --timeout 5m \
    -f "${PROM_VALUES_TMP}"
fi

# ═══════════════════════════════════════════════════════════
echo "[4/6] NetworkPolicy"
# ═══════════════════════════════════════════════════════════
apply "${SCRIPT_DIR}/networkpolicy.yaml"

# ═══════════════════════════════════════════════════════════
echo "[5/6] Ingress для мониторинга"
# ═══════════════════════════════════════════════════════════
apply "${SCRIPT_DIR}/monitoring-ingress.yaml"

# ═══════════════════════════════════════════════════════════
echo "[6/6] Alertmanager patch"
# ═══════════════════════════════════════════════════════════
apply "${SCRIPT_DIR}/alertmanager-patch.yaml"

# ── Итог ──────────────────────────────────────────────────
echo ""
echo "Готово. Адреса:"
echo "  Grafana:      http://${CLUSTER_HOST}:${INGRESS_HTTP_PORT}/grafana"
echo "  Prometheus:   http://${CLUSTER_HOST}:${INGRESS_HTTP_PORT}/prometheus"
echo "  Alertmanager: http://${CLUSTER_HOST}:${INGRESS_HTTP_PORT}/alertmanager"
echo ""
echo "Статус подов мониторинга:"
kubectl get pods -n monitoring
