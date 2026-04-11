variable "create_rds" {
  description = "Habilita creacion de RDS Multi-AZ"
  type        = bool
}

variable "env" {
  description = "Nombre del entorno"
  type        = string
}

variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "data_subnet_ids" {
  description = "Subredes privadas de datos"
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security Group de aplicaciones autorizadas hacia DB"
  type        = string
}

variable "db_identifier" {
  description = "Identificador de la instancia RDS"
  type        = string
}

variable "db_name" {
  description = "Nombre inicial de base de datos"
  type        = string
}

variable "db_username" {
  description = "Usuario maestro de la base de datos"
  type        = string
}

variable "db_password" {
  description = "Password maestro de la base de datos"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "Clase de instancia para RDS"
  type        = string
}

variable "db_allocated_storage" {
  description = "Storage inicial (GB)"
  type        = number
}

variable "db_engine_version" {
  description = "Version de PostgreSQL"
  type        = string
}

variable "db_backup_retention_days" {
  description = "Dias de retencion de backups"
  type        = number
}

variable "db_skip_final_snapshot" {
  description = "Omitir snapshot final al destruir"
  type        = bool
}

variable "key_name" {
  description = "Nombre del par de claves SSH para EC2"
  type        = string
  default     = ""
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

