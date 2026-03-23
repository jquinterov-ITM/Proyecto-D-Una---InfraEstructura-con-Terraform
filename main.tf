module "network" {
  source       = "./modules/network"
  env          = local.current_env
  vpc_cidr     = local.config.vpc_cidr
  pub_subnets  = local.config.pub_subnets
  priv_subnets = local.config.priv_subnets
}

module "security" {
  source   = "./modules/security"
  vpc_id   = module.network.vpc_id
  vpc_cidr = local.config.vpc_cidr
  my_ip    = var.my_ip
  env      = local.current_env
}

module "compute" {
  source          = "./modules/compute"
  public_subnet   = module.network.public_subnets[0]
  private_subnet  = module.network.private_subnets[0]
  sg_master_id    = module.security.sg_master_id
  sg_worker_id    = module.security.sg_worker_id
  master_type     = local.config.master_type
  worker_type     = local.config.worker_type
  k3s_token       = local.k3s_token
  key_name        = var.key_name
  env             = local.current_env
}

module "load_balancer" {
  source             = "./modules/load_balancer"
  vpc_id             = module.network.vpc_id
  public_subnets     = module.network.public_subnets
  worker_instance_id = module.compute.worker_id
  alb_sg_id          = module.security.sg_alb_id
  env                = local.current_env
}