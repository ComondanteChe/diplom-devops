resource "yandex_vpc_network" "k8s_network" {
  name        = "${var.project_name}-network"
  description = "Network for Kubernetes cluster"
}

resource "yandex_vpc_subnet" "k8s_subnet_a" {
  name           = "${var.project_name}-subnet-a"
  description    = "Subnet in zone ru-central1-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.1.0.0/16"]
}

resource "yandex_vpc_subnet" "k8s_subnet_b" {
  name           = "${var.project_name}-subnet-b"
  description    = "Subnet in zone ru-central1-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.2.0.0/16"]
}

resource "yandex_vpc_subnet" "k8s_subnet_d" {
  name           = "${var.project_name}-subnet-d"
  description    = "Subnet in zone ru-central1-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.k8s_network.id
  v4_cidr_blocks = ["10.3.0.0/16"]
}
