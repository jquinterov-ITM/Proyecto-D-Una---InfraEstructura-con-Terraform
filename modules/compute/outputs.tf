output "worker_names" {
  description = "Lista de tags Name de las instancias worker"
  value       = [for w in aws_instance.worker : w.tags["Name"]]
}

output "worker_private_ips" {
  description = "IPs privadas de los workers"
  value       = aws_instance.worker[*].private_ip
}
