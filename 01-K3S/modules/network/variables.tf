variable "vpc_cidr" {
  description = "Rango CIDR para la VPC"
  type        = string
}

variable "pub_subnets" {
  description = "Lista de CIDRs para subnets públicas"
  type        = list(string)
}

variable "app_subnets" {
  description = "Lista de CIDRs para subnets privadas de App/K8s"
  type        = list(string)
}

variable "data_subnets" {
  description = "Lista de CIDRs para subnets privadas de Data/DB"
  type        = list(string)
}

variable "env" {
  description = "Nombre del Entorno (dev/prod)"
  type        = string
}