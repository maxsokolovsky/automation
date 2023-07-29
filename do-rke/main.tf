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
  }
}

provider "digitalocean" {
  token = var.do_token
}

locals {
  kubeconfig_file = "${path.root}/kubeconfig.yml"
}

output "kubeconfig_file" {
  value = local.kubeconfig_file
}

resource "digitalocean_ssh_key" "cluster_pub_key" {
  name       = "max-cluster-key"
  public_key = file(var.ssh_public_key_file)
}

resource "digitalocean_droplet" "nodes" {
  count    = 3
  image    = "ubuntu-20-04-x64"
  name     = "${var.do_node_name_prefix}-${count.index + 1}"
  region   = var.do_region
  size     = var.do_droplet_size
  ssh_keys = [digitalocean_ssh_key.cluster_pub_key.id]
  provisioner "remote-exec" {
    inline = [
      "sleep 30",
      "curl -sL https://releases.rancher.com/install-docker/23.0.sh | sh > /dev/null 2>&1",
    ]
    connection {
      host  = self.ipv4_address
      type  = "ssh"
      user  = var.do_node_user
      agent = true
    }
  }
}

resource "rke_cluster" "do_rke" {
  cluster_name = "do-rke"
  nodes {
    address = digitalocean_droplet.nodes[0].ipv4_address
    user    = var.do_node_user
    role    = ["controlplane", "etcd"]
    ssh_key = file(var.ssh_public_key_file)
  }
  nodes {
    address = digitalocean_droplet.nodes[1].ipv4_address
    user    = var.do_node_user
    role    = ["worker"]
    ssh_key = file(var.ssh_public_key_file)
  }
  nodes {
    address = digitalocean_droplet.nodes[2].ipv4_address
    user    = var.do_node_user
    role    = ["worker"]
    ssh_key = file(var.ssh_public_key_file)
  }

  services {
    kube_api {
      audit_log {
        enabled = true
      }
    }
  }
  enable_cri_dockerd = true
  ssh_agent_auth     = true
  kubernetes_version = var.rke_k8s_version
  upgrade_strategy {
    drain                  = true
    max_unavailable_worker = "100%"
  }
}

resource "local_sensitive_file" "kubeconfig_yaml" {
  depends_on = [
    rke_cluster.do_rke
  ]
  filename = local.kubeconfig_file
  content  = rke_cluster.do_rke.kube_config_yaml
}
