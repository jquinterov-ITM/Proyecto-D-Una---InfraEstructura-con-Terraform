variable "public_subnet" {
  description = "Subred pública para el Master"
  type        = string
}

variable "private_subnet" {
  description = "Subred privada para el Worker"
  type        = string
}

variable "sg_master_id" {
  description = "ID del Security Group del Master"
  type        = string
}

variable "sg_worker_id" {
  description = "ID del Security Group del Worker"
  type        = string
}

variable "master_type" {
  description = "Tipo de instancia para el Master"
  type        = string
}

variable "worker_type" {
  description = "Tipo de instancia para el Worker"
  type        = string
}

variable "k3s_token" {
  description = "Token secreto para unir el clúster"
  type        = string
}

variable "key_name" {
  description = "Nombre de la llave SSH"
  type        = string
}

variable "env" {
  description = "Nombre del entorno"
  type        = string
}