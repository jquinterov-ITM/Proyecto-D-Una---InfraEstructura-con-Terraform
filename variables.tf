#Region
variable "aws_region" {
  description = "Región de AWS donde se desplegarán los recursos"
  default     = "us-east-1"
}

variable "key_name" { default = "vockey" }

variable "create_ec2_iam_resources" {
  description = "Si es true, Terraform crea rol/perfil IAM para EC2 (requiere permisos iam:CreateRole, etc.)"
  type        = bool
  default     = false
}

variable "existing_instance_profile_name" {
  description = "Nombre de instance profile IAM existente para adjuntar a EC2 (opcional)"
  type        = string
  default     = ""
}


variable "my_ip" { default = "201.233.77.14/32" }

locals {
  envs = {
    "dev" = {
      master_count    = 2
      worker_count    = 2
      worker_max_pods = 3
      master_type     = "t3.medium", worker_type = "t3.large"
      vpc_cidr        = "172.16.20.0/22"
      pub_subnets     = ["172.16.20.0/25", "172.16.20.128/25"]
      # Dividir subredes privadas en App y Data (2 subnets cada una)
      app_subnets  = ["172.16.21.0/25", "172.16.21.128/25"]
      data_subnets = ["172.16.22.0/26", "172.16.22.64/26"]
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

variable "enable_https" {
  description = "Habilita listener HTTPS en ALB"
  type        = bool
  default     = true
}

variable "create_acm_certificate" {
  description = "Crear certificado ACM con DNS validation"
  type        = bool
  default     = true
}

variable "acm_certificate_arn" {
  description = "ARN de certificado ACM existente"
  type        = string
  default     = ""
}







variable "create_waf" {
  description = "Crear y asociar WAF al ALB"
  type        = bool
  default     = true
}

variable "create_rds" {
  description = "Habilita creacion de RDS Multi-AZ"
  type        = bool
  default     = false
}

variable "db_identifier" {
  description = "Identificador de instancia RDS"
  type        = string
  default     = "duna-postgres-dev"
}

variable "db_name" {
  description = "Nombre inicial de BD"
  type        = string
  default     = "duna"
}

variable "db_username" {
  description = "Usuario maestro de la BD"
  type        = string
  default     = "dunaadmin"
}

variable "db_password" {
  description = "Password de la BD (requerido si create_rds=true)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_instance_class" {
  description = "Clase de instancia RDS"
  type        = string
  default     = "db.t3.medium"
}

variable "db_allocated_storage" {
  description = "Storage inicial en GB"
  type        = number
  default     = 20
}

variable "db_engine_version" {
  description = "Version de PostgreSQL"
  type        = string
  default     = "16.13"
}

variable "db_backup_retention_days" {
  description = "Dias de retencion de backup"
  type        = number
  default     = 7
}

variable "db_skip_final_snapshot" {
  description = "Omitir snapshot final al destruir RDS"
  type        = bool
  default     = true
}




variable "ado_username" {
  description = "Usuario de Azure DevOps"
  type        = string
  default     = ""
}

variable "ado_pat" {
  description = "Personal Access Token (PAT) de Azure DevOps"
  type        = string
  sensitive   = true
  default     = ""
}


variable "create_storage" {
  description = "Habilita la creacion del bucket S3 para persistencia de la logica de negocio"
  type        = bool
  default     = true
}

variable "assets_bucket_name" {
  description = "Nombre del bucket S3 para assets"
  type        = string
  default     = "duna-assets-12345"
}

variable "cors_allowed_origins" {
  description = "Lista de origenes permitidos en la regla CORS del bucket"
  type        = list(string)
  default     = ["*"]
}


