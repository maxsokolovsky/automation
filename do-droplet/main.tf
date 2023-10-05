terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "docker_pub_key" {
  name       = "max-docker-key"
  public_key = file(var.ssh_public_key_file)
}

resource "digitalocean_droplet" "dockernodes" {
  image    = "ubuntu-20-04-x64"
  count    = var.droplet_count
  name     = format("%s-%d", var.do_node_name_prefix, count.index + 1)
  region   = var.do_region
  size     = var.do_droplet_size
  ssh_keys = [digitalocean_ssh_key.docker_pub_key.id]
}

output "droplet_ip" {
  description = "Droplet IP address"
  value       = digitalocean_droplet.dockernodes[*].ipv4_address
}
