variable "do_token" {
  type      = string
  sensitive = true
}

variable "install_rancher" {
  type    = bool
  default = true
}

variable "bootstrap_password" {
  type      = string
  sensitive = true
}

variable "do_node_name_prefix" {
  type    = string
  default = "max-node"
}

variable "rancher_image" {
  type    = string
  default = "rancher/rancher"
}

variable "rancher_tag" {
  type    = string
  default = "v2.8.2"
}

variable "rancher_agent_image" {
  type    = string
  default = "rancher/rancher-agent"
}

variable "rancher_agent_tag" {
  type    = string
  default = "v2.8.2"
}

variable "do_node_user" {
  type    = string
  default = "root"
}

variable "do_region" {
  type    = string
  default = "nyc3"
}

variable "do_droplet_size" {
  type    = string
  default = "s-4vcpu-8gb-intel"
}

variable "ssh_public_key_file" {
  type        = string
  default     = "./id_rsa.pub"
  description = "which SSH public key to use for access to nodes"
}

variable "domain" {
  type = string
}

variable "subdomain" {
  type = string
}
