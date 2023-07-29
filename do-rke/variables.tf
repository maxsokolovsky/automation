variable "do_token" {
  type      = string
  sensitive = true
}

variable "do_node_name_prefix" {
  type    = string
  default = "max-node"
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
  default = "s-2vcpu-4gb-intel"
}

variable "rke_k8s_version" {
  type    = string
  default = "v1.26.4-rancher2-1"
}

variable "ssh_public_key_file" {
  type        = string
  default     = "./id_rsa.pub"
  description = "which SSH public key to use for node access"
}
