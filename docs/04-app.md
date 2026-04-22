# Приложение и CI/CD

## Приложение

Nginx с кастомной страницей. Исходники в `nginx/`:
- `Dockerfile` — сборка образа
- `nginx.conf` — конфигурация nginx
- `html/index.html` — страница

Эндпоинт `/health` используется для readiness/liveness проб.

## Helm чарт

Приложение упаковано в Helm чарт `helm/nginx-app/`.

```
helm/nginx-app/
├── Chart.yaml          # метаданные чарта
├── values.yaml         # параметры по умолчанию
├── values.prod.yaml    # overrides для prod
└── templates/
    ├── _helpers.tpl    # общие шаблоны (labels, names)
    ├── deployment.yaml
    ├── service.yaml
    └── ingress.yaml
```

### Ключевые параметры values.yaml

```yaml
image:
  registry: cr.yandex/<REGISTRY_ID>
  name: nginx-app
  tag: "v1"

replicaCount: 2

ingress:
  host: "111.88.240.142.nip.io"
  path: /app
```

### Деплой вручную

```bash
source deploy.env
helm upgrade --install nginx-app ./helm/nginx-app \
  --namespace app \
  --create-namespace \
  --set ingress.host=${CLUSTER_HOST} \
  --set image.tag=v1.0.5
```

## CI/CD (GitHub Actions)

Файл: `.github/workflows/ci-cd.yml`

### Триггеры

| Событие | Что происходит |
|---|---|
| Push в любую ветку (`nginx/**`) | Build + Push образа с тегом SHA |
| Push тега `v*.*.*` | Build + Push + Deploy в K8s |

### Переменные и секреты GitHub

**Secrets** (зашифрованы):

| Имя | Описание |
|---|---|
| `CI_CD_DIPLOM` | Yandex Cloud OAuth токен |
| `KUBE_CONFIG` | kubeconfig в base64 |

**Variables** (открытые):

| Имя | Значение |
|---|---|
| `REGISTRY` | `cr.yandex/<REGISTRY_ID>` |
| `IMAGE_NAME` | `nginx-app` |
| `CLUSTER_HOST` | `111.88.240.142.nip.io` |

### Схема пайплайна

```
git tag v1.0.5 && git push --tags
        │
        ▼
  build-and-push
  ├── Checkout code
  ├── Set image tag (= git tag)
  ├── Login to Yandex Registry (OAuth → IAM token)
  ├── docker build ./nginx/
  ├── docker push :v1.0.5
  └── docker push :latest
        │
        ▼
     deploy
  ├── Setup kubectl + helm
  ├── Configure kubeconfig (без CA, insecure-skip-tls-verify)
  ├── Refresh IAM token → kubectl secret yc-registry
  └── helm upgrade --install nginx-app (--set image.tag=v1.0.5)
```

### Откат версии

```bash
# Через Helm
helm history nginx-app -n app
helm rollback nginx-app <REVISION> -n app

# Через git tag (задеплоит старую версию)
git tag v1.0.4-hotfix v1.0.4
git push origin v1.0.4-hotfix
```
