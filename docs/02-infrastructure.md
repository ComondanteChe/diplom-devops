# Инфраструктура: ВМ, сеть и Kubernetes

## Что создаётся Terraform

- **VPC сеть** с тремя подсетями (ru-central1-a, b, d)
- **Security Group** с правилами для K8s, ingress, SSH
- **Зарезервированный статический IP** для мастера
- **ВМ**: 1 мастер + 2 воркера (прерываемые, Ubuntu 22.04)
- **Ansible inventory** — генерируется автоматически из Terraform outputs

## Применение

```bash
cd infrastructure
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
```

## Параметры ВМ (defaults в variables.tf)

| Параметр | Мастер | Воркер |
|---|---|---|
| CPU | 2 core / 20% | 2 core / 20% |
| RAM | 2 GB | 2 GB |
| Disk | 20 GB HDD | 20 GB HDD |
| IP | Статический | Динамический NAT |

## Установка Kubernetes через Ansible

После `terraform apply` inventory автоматически генерируется в `ansible/inventory/hosts.ini`.

```bash
cd ansible
ansible-playbook -i inventory/hosts.ini site.yml
```

**Роли:**
- `common` — базовая настройка: containerd, kubeadm, kubelet, kubectl
- `k8s_master` — `kubeadm init`, Calico CNI, генерация join-команды
- `k8s_worker` — `kubeadm join`

## После установки кластера

```bash
# Получить kubeconfig
scp ubuntu@<MASTER_IP>:~/.kube/config ~/.kube/config

# Установить local-path-provisioner (нужен для PVC)
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
kubectl patch storageclass local-path \
  -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Сетевая схема

```
Internet
    │
    ▼ Static IP (master)
┌─────────────────────────────────┐
│         Security Group          │
│  22 (SSH), 6443 (K8s API)       │
│  30000-32767 (NodePort)         │
│  443 (HTTPS)                    │
│  ANY internal (self_sg, IPIP!)  │
└─────────────────────────────────┘
    │
    ▼
┌───────────────────────────────────────┐
│  VPC Network                          │
│                                       │
│  10.1.0.0/16 (ru-central1-a)         │
│  ├── master-1 (10.1.0.x) Static IP   │
│  └── worker-1 (10.1.0.x) NAT         │
│                                       │
│  10.2.0.0/16 (ru-central1-b)         │
│  └── worker-2 (10.2.0.x) NAT         │
└───────────────────────────────────────┘

Pod network: 10.244.0.0/16 (Calico IPIP)
```
