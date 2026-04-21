output "master_public_ip" {
  value = module.compute.master_ip
}

output "alb_dns_name" {
  value = module.load_balancer.alb_dns
}