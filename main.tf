locals {
  https_enabled = var.enable_https && var.acm_certificate_arn != ""
}
module "network" {
  source       = "./modules/network"
  env          = local.current_env
  vpc_cidr     = local.config.vpc_cidr
  pub_subnets  = local.config.pub_subnets
  app_subnets  = local.config.app_subnets
  data_subnets = local.config.data_subnets
}
module "security" {
  source   = "./modules/security"
  vpc_id   = module.network.vpc_id
  vpc_cidr = local.config.vpc_cidr
  my_ip    = var.my_ip
  env      = local.current_env
}
module "compute" {
  source                         = "./modules/compute"
  app_subnets                    = module.network.app_private_subnets
  app_subnet_cidrs               = local.config.app_subnets
  sg_master_id                   = module.security.sg_master_id
  sg_worker_id                   = module.security.sg_worker_id
  master_count                   = length(local.config.app_subnets)
  worker_count                   = local.config.worker_count
  worker_max_pods                = local.config.worker_max_pods
  master_type                    = local.config.master_type
  worker_type                    = local.config.worker_type
  k3s_token                      = local.k3s_token
  key_name                       = var.key_name
  env                            = local.current_env
  create_ec2_iam_resources       = var.create_ec2_iam_resources
  existing_instance_profile_name = var.existing_instance_profile_name
}
module "load_balancer" {
  source              = "./modules/load_balancer"
  vpc_id              = module.network.vpc_id
  public_subnets      = module.network.public_subnets
  worker_instance_ids = module.compute.worker_ids
  alb_sg_id           = module.security.sg_alb_id
  env                 = local.current_env
  enable_https        = local.https_enabled

  acm_certificate_arn = var.acm_certificate_arn
}
module "edge" {
  source     = "./modules/edge"
  env        = local.current_env
  create_waf = var.create_waf
  alb_arn    = module.load_balancer.alb_arn
}
module "data" {
  source                   = "./modules/data"
  key_name                 = var.key_name
  create_rds               = var.create_rds
  env                      = local.current_env
  ado_username             = var.ado_username
  ado_pat                  = var.ado_pat
  vpc_id                   = module.network.vpc_id
  data_subnet_ids          = module.network.data_private_subnets
  app_sg_id                = module.security.sg_worker_id
  db_identifier            = var.db_identifier
  db_name                  = var.db_name
  db_username              = var.db_username
  db_password              = var.db_password
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_engine_version        = var.db_engine_version
  db_backup_retention_days = var.db_backup_retention_days
  db_skip_final_snapshot   = var.db_skip_final_snapshot
}
output "main_route_table_id" {
  value = module.network.main_route_table_id
}
output "worker_names" {
  description = "Nombres de los workers creados por el módulo compute"
  value       = module.compute.worker_names
}
output "worker_private_ips" {
  description = "IPs privadas de los workers creados por el módulo compute"
  value       = module.compute.worker_private_ips
}
output "master_private_ips" {
  description = "IPs privadas fijas de los masters"
  value       = module.compute.master_private_ips
}
output "master_primary_private_ip" {
  description = "IP privada del master primario para administración interna"
  value       = module.compute.master_private_ips[0]
}
output "master_primary_instance_id" {
  description = "Instance ID del master primario"
  value       = module.compute.master_primary_id
}
output "master_instance_ids" {
  description = "Instance IDs de todos los masters"
  value       = module.compute.master_ids
}
module "storage" {
  source               = "./modules/storage"
  env                  = local.current_env
  bucket_name          = var.assets_bucket_name
  cors_allowed_origins = var.cors_allowed_origins
}



