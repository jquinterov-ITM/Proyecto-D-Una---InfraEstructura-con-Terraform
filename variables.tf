#Region
variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  default     = "us-east-1"
}

variable "key_name"   { default = "vockey" }


variable "my_ip"      { default = "201.233.77.14/32" }

locals {
  envs = {
    "dev" = {
      master_type  = "t3.medium", worker_type = "t3.large"
      vpc_cidr     = "172.16.20.0/22"
      pub_subnets  = ["172.16.20.0/25", "172.16.20.128/25"]
      #priv_subnets = ["172.16.21.0/25", "172.16.21.128/25"]
      priv_subnets = ["172.16.21.0/25", "172.16.21.128/25",
                      "172.16.22.0/26", "172.16.22.64/26",
                      "172.16.22.128/26", "172.16.22.192/26"]
    }
    
    #"prod" = {
    #  master_type  = "t3.large", worker_type = "c5.xlarge"
    # vpc_cidr     = "172.20.2.0/23"
    #  pub_subnets  = ["172.20.2.0/26", "172.20.2.64/26"]
    #  priv_subnets = ["172.20.2.128/26", "172.20.2.192/26"]
    #}
  }
  current_env = contains(keys(local.envs), terraform.workspace) ? terraform.workspace : "dev"
  config      = local.envs[local.current_env]
  k3s_token   = "K3s-Secret-2026-Token"
}

#Profile
variable "aws_profile" {
  default = "default"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "Proyecto_D-una"
}

