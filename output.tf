output "master_server_public_ip" {
  description = "Public IP of the master server"
  value = module.master.server_ip
}

output "worker_server_public_ip" {
  description = "Public IP of the worker server"
  value = module.worker.server_ip
  
}
output "prometheus_server_public_ip" {
  description = "Public IP of the Prometheus server"
  value = module.prometheus_server.server_ip
  
}
