output "app_server_1_open_tunnel_command" {
  description = "Command that opens an SSH tunnel to the App Server instance."
  value       = "${module.master.ssh} -f tail -f /dev/null"
}

output "vpc-name" {
  value = module.google_networks.network.name
}