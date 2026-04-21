output "master_nodes" {
  description = "Master nodes information"
  value = {
    for idx, instance in yandex_compute_instance.k8s_master :
    instance.name => {
      internal_ip = instance.network_interface[0].ip_address
      external_ip = instance.network_interface[0].nat_ip_address
      zone        = instance.zone
    }
  }
}

output "worker_nodes" {
  description = "Worker nodes information"
  value = {
    for idx, instance in yandex_compute_instance.k8s_worker :
    instance.name => {
      internal_ip = instance.network_interface[0].ip_address
      external_ip = instance.network_interface[0].nat_ip_address
      zone        = instance.zone
    }
  }
}

output "ingress_nip_io" {
  description = "nip.io address for ingress (via master static IP)"
  value       = "${yandex_vpc_address.master_ips[0].external_ipv4_address[0].address}.nip.io"
}

output "network_id" {
  description = "Network ID"
  value       = yandex_vpc_network.k8s_network.id
}

output "subnet_ids" {
  description = "Subnet IDs"
  value = {
    "ru-central1-a" = yandex_vpc_subnet.k8s_subnet_a.id
    "ru-central1-b" = yandex_vpc_subnet.k8s_subnet_b.id
    "ru-central1-d" = yandex_vpc_subnet.k8s_subnet_d.id
  }
}

resource "local_file" "ansible_incventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    master_nodes = [
      for instance in yandex_compute_instance.k8s_master : {
        name         = instance.name
        ansible_host = instance.network_interface[0].nat_ip_address
        ip           = instance.network_interface[0].ip_address
      }
    ]
    worker_nodes = [
      for instance in yandex_compute_instance.k8s_worker : {
        name         = instance.name
        ansible_host = instance.network_interface[0].nat_ip_address
        ip           = instance.network_interface[0].ip_address
      }
    ]
    ssh_user = var.ssh_user
  })
  filename = "${path.module}/ansible/inventory/hosts.ini"

  depends_on = [
    yandex_compute_instance.k8s_master,
    yandex_compute_instance.k8s_worker
  ]
}

output "ansible_inventory_path" {
  description = "Path inventory file"
  value       = local_file.ansible_incventory.filename
}