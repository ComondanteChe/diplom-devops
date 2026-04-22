# ──────────────────────────────────────────────
# Security Group для Kubernetes
# ──────────────────────────────────────────────

resource "yandex_vpc_security_group" "k8s_sg" {
  name        = "${var.project_name}-k8s-sg"
  description = "Security group for Kubernetes cluster"
  network_id  = yandex_vpc_network.k8s_network.id

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = "22"
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = "443"
  }

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes API"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = "6443"
  }

  ingress {
    protocol       = "TCP"
    description    = "Kubernetes NodePort range (includes ingress-nginx :32080)"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = "30000"
    to_port        = "32767"
  }

  ingress {
    protocol          = "ANY"
    description       = "Internal cluster communication (includes IPIP for Calico)"
    predefined_target = "self_security_group"
  }

  ingress {
    protocol       = "ICMP"
    description    = "ICMP ping"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}