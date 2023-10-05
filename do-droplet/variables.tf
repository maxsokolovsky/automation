variable "do_token" {
  type      = string
  sensitive = true
}

variable "droplet_count" {
  type    = number
  default = 1
}

variable "do_node_name_prefix" {
  type    = string
  default = "max-node"
}

variable "do_region" {
  type    = string
  default = "nyc1"
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
