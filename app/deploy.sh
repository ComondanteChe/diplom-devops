#!/bin/bash
set -e

REGISTRY="cr.yandex/crp9d347bcdius5nhmk8"
IMAGE="$REGISTRY/nginx-app:v1"
NAMESPACE="app"

# Создать namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Создать секрет для pull из Yandex Container Registry
kubectl create secret docker-registry yc-registry \
  --namespace=$NAMESPACE \
  --docker-server=cr.yandex \
  --docker-username=iam \
  --docker-password=$(yc iam create-token) \
  --dry-run=client -o yaml | kubectl apply -f -

# Деплой
kubectl apply -f deployment.yaml

echo ""
echo "App will be available at: http://111.88.240.142.nip.io:32080/app"
