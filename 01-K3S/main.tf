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
  source           = "./modules/compute"
  public_subnet    = module.network.public_subnets[0]
  app_subnets      = [module.network.public_subnets[0], module.network.app_private_subnets[0], module.network.app_private_subnets[0]]
  app_subnet_cidrs = [local.config.pub_subnets[0], local.config.app_subnets[0], local.config.app_subnets[0]]
  sg_master_id     = module.security.sg_master_id
  sg_worker_id     = module.security.sg_worker_id
  master_count     = local.config.master_count
  worker_count     = local.config.worker_count
  worker_max_pods  = local.config.worker_max_pods
  master_type      = local.config.master_type
  worker_type      = local.config.worker_type
  k3s_token        = local.k3s_token
  key_name         = var.key_name
  env              = local.current_env
}

module "load_balancer" {
  source              = "./modules/load_balancer"
  vpc_id              = module.network.vpc_id
  public_subnets      = module.network.public_subnets
  worker_instance_ids = module.compute.worker_ids
  alb_sg_id           = module.security.sg_alb_id
  env                 = local.current_env
}