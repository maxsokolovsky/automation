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

resource "digitalocean_droplet" "dockernode" {
  image    = "ubuntu-24-04-x64"
  name     = format("%s", var.do_node_name_prefix)
  region   = var.do_region
  size     = var.do_droplet_size
  ssh_keys = [digitalocean_ssh_key.docker_pub_key.id]
  tags     = [digitalocean_tag.owner.id]
  provisioner "remote-exec" {
    inline = [
      <<EOT
      sleep 30
      curl https://releases.rancher.com/install-docker/${var.docker_version}.sh | sh
      sudo usermod -aG docker root
      if "${var.install_rancher}" == true; then
        docker run -d -p 80:80 -p 443:443 \
          -e CATTLE_AGENT_IMAGE=${var.rancher_agent_image}:${var.rancher_agent_tag} \
          -e CATTLE_BOOTSTRAP_PASSWORD=${var.bootstrap_password} \
          --restart=unless-stopped \
          --privileged --name rancher ${var.rancher_image}:${var.rancher_tag} >/dev/null 2>&1
      fi
      EOT
    ]
    connection {
      host  = self.ipv4_address
      type  = "ssh"
      user  = var.do_node_user
      agent = true
    }
  }
}

resource "digitalocean_record" "dns" {
  name   = var.subdomain
  domain = var.domain
  type   = "A"
  value  = digitalocean_droplet.dockernode.ipv4_address
}

resource "digitalocean_tag" "owner" {
  name = "owner:max"
}

output "dns_address" {
  depends_on = [
    digitalocean_record.dns,
  ]
  value = "https://${digitalocean_record.dns.name}.${digitalocean_record.dns.domain}"
}

output "droplet_ip" {
  description = "Droplet IP address"
  value       = digitalocean_droplet.dockernode.ipv4_address
}
