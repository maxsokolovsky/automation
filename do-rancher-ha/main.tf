terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2"
    }
    rke = {
      source  = "rancher/rke"
      version = "~> 1"
    }
    time = {
      source = "hashicorp/time"
    }
    helm = {
      source = "hashicorp/helm"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

provider "helm" {
  kubernetes {
    config_path = local_sensitive_file.kubeconfig_yaml.filename
  }
}

locals {
  etcd_user_id              = "52034"
  etcd_group_id             = "52034"
  kubeconfig_file           = "${path.module}/files/kubeconfig.yml"
  kubelet_tls_cipher_suites = "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256"
  kubelet_feature_gates     = "RotateKubeletServerCertificate=true"
  cert_manager_version      = "v1.12.2"
}

resource "local_file" "cloud_config_rendered" {
  filename        = "${path.module}/files/cloud-config-rendered.yaml"
  file_permission = "0600"
  content = templatefile("${path.module}/files/cloud-config.yaml", {
    init_ssh_public_key = trimspace(file(var.ssh_public_key_file))
    docker_version      = "23.0"
    etcd_group_id       = local.etcd_group_id
    etcd_user_id        = local.etcd_user_id
  })
}

resource "digitalocean_ssh_key" "cluster_pub_key" {
  name       = "max-cluster-key"
  public_key = file(var.ssh_public_key_file)
}

resource "digitalocean_droplet" "control_plane" {
  count     = var.node_count
  image     = "ubuntu-20-04-x64"
  name      = format("%s-%s-%s", var.do_node_name_prefix, "cp", count.index + 1)
  region    = var.do_region
  size      = var.do_droplet_size
  user_data = local_file.cloud_config_rendered.content
  ssh_keys  = [digitalocean_ssh_key.cluster_pub_key.id]
  tags      = [digitalocean_tag.owner.id]

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = "root"
      agent = true
      host  = self.ipv4_address
    }
    inline = ["bash -c 'for i in range{1..10}; do systemctl is-active -q docker; if [ $? == 0 ]; then exit 0; fi; sleep 30; done; exit -1;'"]
  }
}

resource "digitalocean_tag" "owner" {
  name = "owner:max"
}

resource "digitalocean_record" "dns" {
  domain = var.domain
  type   = "A"
  name   = var.subdomain
  value  = digitalocean_droplet.control_plane[0].ipv4_address
}

resource "rke_cluster" "do_rke_ha" {
  cluster_name = "do-rke-ha"
  depends_on = [
    digitalocean_droplet.control_plane
  ]
  enable_cri_dockerd = true
  ssh_agent_auth     = true
  kubernetes_version = var.rke_k8s_version
  dynamic "nodes" {
    for_each = range(0, var.node_count)
    content {
      address = digitalocean_droplet.control_plane[nodes.value].ipv4_address
      user    = var.do_node_user
      role = [
        "controlplane",
        "etcd",
        "worker",
      ]
      ssh_key_path = var.ssh_private_key_file
    }
  }
  network {
    plugin = "canal"
  }
  services {
    etcd {
      retention = "72h"
      snapshot  = false
      gid       = local.etcd_group_id
      uid       = local.etcd_user_id
      backup_config {
        enabled = false
      }
      creation = "12h"
      extra_args = {
        election-timeout   = "5000"
        heartbeat-interval = "500"
      }
    }
    kubelet {
      fail_swap_on                 = false
      generate_serving_certificate = true
      extra_args = {
        feature-gates           = local.kubelet_feature_gates
        protect-kernel-defaults = "true"
        tls-cipher-suites       = local.kubelet_tls_cipher_suites
      }
      extra_binds = ["/volumes/rancher:/volumes/rancher"]
    }
    kube_controller {
      extra_args = {
        feature-gates = local.kubelet_feature_gates
      }
    }
    kube_api {
      always_pull_images      = false
      pod_security_policy     = false
      service_node_port_range = "30000-32767"
      audit_log {
        enabled = true
      }
      secrets_encryption_config {
        enabled = true
      }
    }
  }
  upgrade_strategy {
    drain                        = true
    max_unavailable_controlplane = 1
    max_unavailable_worker       = "10%"
  }
}

resource "local_sensitive_file" "kubeconfig_yaml" {
  depends_on = [
    rke_cluster.do_rke_ha,
  ]
  filename        = local.kubeconfig_file
  file_permission = "0600"
  content         = rke_cluster.do_rke_ha.kube_config_yaml
}

resource "local_sensitive_file" "rke_cluster_yaml" {
  depends_on = [
    rke_cluster.do_rke_ha,
  ]
  filename        = "${path.module}/files/cluster.yaml"
  file_permission = "0600"
  content         = rke_cluster.do_rke_ha.rke_cluster_yaml
}

resource "helm_release" "cert_manager" {
  count = var.install_rancher ? 1 : 0
  depends_on = [
    local_sensitive_file.kubeconfig_yaml,
  ]
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = local.cert_manager_version
  create_namespace = true
  namespace        = "cert-manager"
  timeout          = 120
  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "helm_release" "rancher" {
  count            = var.install_rancher ? 1 : 0
  depends_on       = [helm_release.cert_manager]
  repository       = "https://releases.rancher.com/server-charts/latest"
  name             = "rancher"
  chart            = "rancher"
  version          = var.rancher_version
  create_namespace = true
  namespace        = "cattle-system"
  set {
    name  = "hostname"
    value = digitalocean_record.dns.fqdn
  }
  set {
    name  = "replicas"
    value = var.node_count
  }
  set {
    name  = "bootstrapPassword"
    value = var.bootstrap_password
  }
}
