#Region
variable "key_name"   { default = "testKey" }
#variable "my_ip"      { default = "201.233.77.14/32" } # mi ip publica con mascara
variable "my_ip"      { default = "0.0.0.0/0" }

variable "env" {
  description = "Execution environment"
  type        = string
  default     = "dev"
}

locals {
  envs = {
    "dev" = {
      worker_count    = 2
      worker_max_pods = 7
      master_type     = "t3.medium", worker_type = "t3.large"
      vpc_cidr        = "172.16.20.0/22"
      pub_subnets     = ["172.16.20.0/25", "172.16.20.128/25"]
      # Dividir subredes privadas en App y Data (2 subnets cada una)
      app_subnets  = ["172.16.21.0/25", "172.16.21.128/25"]
      data_subnets = ["172.16.22.0/26", "172.16.22.64/26"]
    }
  }
  current_env = contains(keys(local.envs), terraform.workspace) ? terraform.workspace : "dev"
  config      = local.envs[local.current_env]
  k3s_token   = "K3s-Secret-2026-Token"
}


variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "Proyecto_D-una"
}

variable "aws_profile" {
  description = "AWS Profile to use"
  type        = string
  default     = "default"
}