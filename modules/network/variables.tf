variable "vpc_cidr" {
    description = "Rango CIDR para la VPC"
    type        = string
    
}

variable "pub_subnets" {
    description = "Lista de CIDRs para subnets públicas"
    type        = list(string)
}

variable "priv_subnets" {
    description = "Lista de CIDRs para subnets privadas"
    type        = list(string)
}

variable "env" {
    description = "Nombre del Entorno (dev/prod)"
    type        = string
}