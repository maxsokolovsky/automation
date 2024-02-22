variable "ssh_public_key_file" {
  type        = string
  default     = "./id_rsa.pub"
  description = "which SSH public key to use for access to nodes"
}

variable "ssh_private_key_file" {
  type        = string
  default     = "./id_rsa"
  description = "which SSH private key to use for installing RKE, recommended to use encrypted private key and run ssh-agent"
}

variable "do_token" {
  type        = string
  sensitive   = true
  description = "DigitalOcean token"
}

variable "do_node_name_prefix" {
  type        = string
  description = "the desired prefix for the DigitalOcean node names"
}

variable "do_node_user" {
  type        = string
  description = "the DigitalOcean node SSH user"
  default     = "root"
}

variable "do_region" {
  type        = string
  description = "the region in which to provision the nodes"
}

variable "do_droplet_size" {
  type        = string
  default     = "s-2vcpu-4gb-intel"
  description = "CPU, memory, architecture spec for a node"
}

variable "domain" {
  type = string
  validation {
    condition     = length(var.domain) > 0
    error_message = "The domain variable must be non-empty."
  }
  default     = "cp-dev.rancher.space"
  description = "Rancher domain"
}

variable "subdomain" {
  type = string
  validation {
    condition     = length(var.subdomain) > 0
    error_message = "The subdomain variable must be non-empty."
  }
  description = "subdomain for this installation of Rancher"
}

variable "rke_k8s_version" {
  type        = string
  description = "Kubernetes version to install"
}

variable "rancher_image" {
  type    = string
  default = "rancher/rancher"
}

variable "rancher_version" {
  type = string
  validation {
    condition     = !startswith(var.rancher_version, "v")
    error_message = "Specify rancher_version without the leading 'v'."
  }
}

variable "node_count" {
  type = number
  validation {
    condition     = var.node_count % 2 != 0
    error_message = "The number of nodes must be even."
  }
}

variable "install_rancher" {
  type        = bool
  default     = true
  description = "Whether to install Rancher"
}

variable "bootstrap_password" {
  type        = string
  sensitive   = true
  description = "Rancher bootstrap password"
}
