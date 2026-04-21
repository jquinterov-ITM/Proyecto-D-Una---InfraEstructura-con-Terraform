variable "vpc_id" {
  description = "ID de la VPC creada en el módulo network"
  type        = string
}

variable "vpc_cidr" {
  description = "Rango CIDR de la VPC para reglas internas"
  type        = string
}

variable "my_ip" {
  description = "Tu IP pública con /32 para acceso administrativo"
  type        = string
}

variable "env" {
  description = "Nombre del entorno"
  type        = string
}