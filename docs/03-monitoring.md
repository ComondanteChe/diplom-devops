# Мониторинг: Prometheus, Grafana, Alertmanager

## Состав

`kube-prometheus-stack` включает:
- **Prometheus** — сбор метрик
- **Grafana** — дашборды (встроенные для K8s, нод, подов)
- **Alertmanager** — маршрутизация алертов
- **Node Exporter** — метрики нод
- **Kube State Metrics** — метрики K8s объектов
- **Prometheus Operator** — управление через CRD

## Деплой

```bash
./monitoring/deploy-monitoring.sh
```

Скрипт выполняет по порядку:
1. `local-path-provisioner` — StorageClass для PVC
2. `ingress-nginx` — NodePort ingress контроллер
3. `kube-prometheus-stack` — Helm чарт
4. `NetworkPolicy` — разрешает трафик внутри namespace
5. `Ingress` — маршруты /grafana, /prometheus, /alertmanager
6. `Alertmanager patch` — устанавливает routePrefix

## Доступ

| Сервис | URL | Логин |
|---|---|---|
| Grafana | `http://<IP>.nip.io:32080/grafana` | admin / admin |
| Prometheus | `http://<IP>.nip.io:32080/prometheus` | — |
| Alertmanager | `http://<IP>.nip.io:32080/alertmanager` | — |

## Конфигурация

Все параметры в `monitoring/prometheus-values.yaml`. Переменные `${CLUSTER_HOST}` и `${INGRESS_HTTP_PORT}` подставляются из `deploy.env` через `envsubst`.

## NodePort сервисы (прямой доступ без ingress)

| Сервис | NodePort |
|---|---|
| Grafana | 30300 |
| Prometheus | 30900 |
| Alertmanager | 30930 |

## Хранение данных

| Компонент | PVC размер |
|---|---|
| Prometheus | 2 GB (retention: 1 день) |
| Alertmanager | 5 GB |
| Grafana | 10 GB |

> **Внимание:** `local-path-provisioner` хранит данные локально на ноде. При переезде пода данные теряются.

## Известные особенности

- **kube-controller-manager и kube-scheduler** слушают на `127.0.0.1` по умолчанию в kubeadm — нужно изменить `bind-address` на `0.0.0.0` в статических манифестах на мастере для корректного сбора метрик
- **kube-proxy** метрики: `metricsBindAddress: "0.0.0.0:10249"` в ConfigMap
- **etcd** метрики: `listen-metrics-urls: http://0.0.0.0:2381`
