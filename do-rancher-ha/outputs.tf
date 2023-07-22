output "node_ips" {
  depends_on  = [digitalocean_droplet.control_plane]
  description = "IP Addresses of the DigitalOcean Node"
  value       = [digitalocean_droplet.control_plane.*.ipv4_address]
}

output "kubeconfig_file" {
  description = "RKE Cluster kubeconfig file location"
  value       = local_sensitive_file.kubeconfig_yaml.filename
}

output "rke_cluster_file" {
  description = "RKE Cluster configuration file, obtained after provisoining the cluster"
  value       = local_sensitive_file.rke_cluster_yaml.filename
}

output "rancher_server_url" {
  depends_on = [
    digitalocean_record.dns,
  ]
  description = "URL of the up and running Rancher server"
  value       = "https://${digitalocean_record.dns.name}.${digitalocean_record.dns.domain}"
}
