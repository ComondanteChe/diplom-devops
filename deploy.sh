#!/bin/bash
# Deploy K8s manifests with environment substitution
# Usage: ./deploy.sh [component]
#   ./deploy.sh all           - deploy everything
#   ./deploy.sh monitoring    - deploy monitoring stack
#   ./deploy.sh app           - deploy nginx app
#   ./deploy.sh atlantis      - deploy atlantis

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load variables
if [[ -f "${SCRIPT_DIR}/deploy.env" ]]; then
  source "${SCRIPT_DIR}/deploy.env"
else
  echo "ERROR: deploy.env not found. Copy deploy.env and fill in your values."
  exit 1
fi

export CLUSTER_HOST INGRESS_HTTP_PORT INGRESS_HTTPS_PORT

apply() {
  local file="$1"
  echo "Applying: ${file}"
  envsubst < "${file}" | kubectl apply -f -
}

helm_install_monitoring() {
  echo "==> ingress-nginx"
  envsubst < "${SCRIPT_DIR}/monitoring/ingress-values.yaml" | \
    helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
      --namespace ingress-nginx --create-namespace \
      -f -

  echo "==> kube-prometheus-stack"
  envsubst < "${SCRIPT_DIR}/monitoring/prometheus-values.yaml" | \
    helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
      --namespace monitoring --create-namespace \
      -f -

  apply "${SCRIPT_DIR}/monitoring/monitoring-ingress.yaml"
  apply "${SCRIPT_DIR}/monitoring/networkpolicy.yaml"
  kubectl apply -f <(envsubst < "${SCRIPT_DIR}/monitoring/alertmanager-patch.yaml")
}

deploy_app() {
  apply "${SCRIPT_DIR}/app/deployment.yaml"
}

deploy_atlantis() {
  apply "${SCRIPT_DIR}/atlantis/atlantis.yaml"
}

COMPONENT="${1:-all}"

case "${COMPONENT}" in
  all)
    helm_install_monitoring
    deploy_app
    deploy_atlantis
    ;;
  monitoring)
    helm_install_monitoring
    ;;
  app)
    deploy_app
    ;;
  atlantis)
    deploy_atlantis
    ;;
  *)
    echo "Unknown component: ${COMPONENT}"
    echo "Usage: $0 [all|monitoring|app|atlantis]"
    exit 1
    ;;
esac

echo "Done."
