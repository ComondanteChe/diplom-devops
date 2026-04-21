# ──────────────────────────────────────────────
# Master nodes for Kubernetes
# ──────────────────────────────────────────────

resource "yandex_vpc_address" "master_ips" {
  count = var.master_count
  name  = "${var.project_name}-master-${count.index + 1}-ip"
  external_ipv4_address {
    zone_id = var.zones[count.index % length(var.zones)]
  }
}

resource "yandex_compute_instance" "k8s_master" {
  count       = var.master_count
  name        = "${var.project_name}-master-${count.index + 1}"
  hostname    = "master-${count.index + 1}"
  platform_id = "standard-v2"
  description = "Kubernetes master node"
  zone        = var.zones[count.index % length(var.zones)]

  resources {
    cores         = var.master_cpu
    memory        = var.master_memory
    core_fraction = var.master_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.master_disk_size
      type     = var.master_disk_type
    }
  }

  network_interface {
    subnet_id          = local.zone_to_subnet[var.zones[count.index % length(var.zones)]]
    nat                = true
    nat_ip_address     = yandex_vpc_address.master_ips[count.index].external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = true
  }

  labels = {
    role    = "master"
    cluster = "var.project_name"
  }
}

# ──────────────────────────────────────────────
# Worker nodes for Kubernetes
# ──────────────────────────────────────────────

resource "yandex_compute_instance" "k8s_worker" {
  count = var.worker_count

  name        = "${var.project_name}-worker-${count.index + 1}"
  hostname    = "worker-${count.index + 1}"
  platform_id = "standard-v2"
  description = "Kubernetes worker node"
  zone        = var.zones[count.index % length(var.zones)]

  resources {
    cores         = var.worker_cpu
    memory        = var.worker_memory
    core_fraction = var.worker_core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.worker_disk_size
      type     = var.worker_disk_type
    }
  }

  network_interface {
    subnet_id          = local.zone_to_subnet[var.zones[count.index % length(var.zones)]]
    nat                = true
    security_group_ids = [yandex_vpc_security_group.k8s_sg.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${local.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = true
  }

  labels = {
    role    = "worker"
    cluster = "var.project_name"
  }
}