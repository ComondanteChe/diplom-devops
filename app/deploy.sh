#!/bin/bash
set -euo pipefail

REGISTRY="cr.yandex/crp9d347bcdius5nhmk8"
IMAGE="$REGISTRY/nginx-app:v1"
NAMESPACE="app"

# Load cluster variables from root deploy.env
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${SCRIPT_DIR}/../deploy.env" ]]; then
  source "${SCRIPT_DIR}/../deploy.env"
fi

export CLUSTER_HOST="${CLUSTER_HOST:-<MASTER_IP>.nip.io}"
export INGRESS_HTTP_PORT="${INGRESS_HTTP_PORT:-32080}"

# Создать namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Создать секрет для pull из Yandex Container Registry
kubectl create secret docker-registry yc-registry \
  --namespace=$NAMESPACE \
  --docker-server=cr.yandex \
  --docker-username=iam \
  --docker-password=$(yc iam create-token) \
  --dry-run=client -o yaml | kubectl apply -f -

# Деплой с подстановкой переменных
envsubst < "${SCRIPT_DIR}/deployment.yaml" | kubectl apply -f -

echo ""
echo "App will be available at: http://${CLUSTER_HOST}:${INGRESS_HTTP_PORT}/app"
