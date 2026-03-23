variable "vpc_id" {
  description = "ID de la VPC"
  type        = string
}

variable "public_subnets" {
  description = "Lista de subredes públicas para el ALB"
  type        = list(string)
}

variable "worker_instance_id" {
  description = "ID de la instancia Worker para el Target Group"
  type        = string
}

variable "alb_sg_id" {
  description = "ID del Security Group del ALB"
  type        = string
}

variable "env" {
  description = "Nombre del entorno"
  type        = string
}