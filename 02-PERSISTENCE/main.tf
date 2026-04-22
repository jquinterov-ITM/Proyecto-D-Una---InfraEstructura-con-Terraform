data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["VPC-*"] # Ajustado a VPC-Duna o VPC-${var.env}
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "tag:Name"
    values = ["Private-Data-*"] # Ajustado a Name = "Private-Data-${var.env}-${count.index}"
  }
}

data "aws_security_group" "worker_sg" {
  filter {
    name   = "group-name"
    values = ["SG-Worker-*"] # Ajustado a SG-Worker-${var.env}
  }
}

module "database" {
  source                   = "./modules/db"
  vpc_id                   = data.aws_vpc.main.id
  #key_name                 = var.key_name
  #create_rds               = var.create_rds
  #env                      = local.current_env
  #ado_username             = var.ado_username
  #ado_pat                  = var.ado_pat
  subnet_ids               = data.aws_subnets.private.ids
  worker_sg_id          = data.aws_security_group.worker_sg.id
  #db_identifier            = var.db_identifier
  #db_name                  = var.db_name
  #db_username              = var.db_username
  db_instance_class        = var.db_instance_class
  db_allocated_storage     = var.db_allocated_storage
  db_password              = var.db_password
  #db_engine_version        = var.db_engine_version
  #db_backup_retention_days = var.db_backup_retention_days
  #db_skip_final_snapshot   = var.db_skip_final_snapshot
}

module "storage" {
  source               = "./modules/storage"
  vpc_id             = data.aws_vpc.main.id
  subnet_ids         = data.aws_subnets.private.ids
  worker_sg_id       = data.aws_security_group.worker_sg.id
}