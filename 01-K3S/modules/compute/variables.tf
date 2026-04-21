variable "public_subnet" {
  description = "Subred pública para el Master"
  type        = string
}

variable "app_subnets" {
  description = "Lista de subredes privadas App/K3s donde crear workers"
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "Lista de CIDRs de subredes privadas App/K8s"
  type        = list(string)
}

variable "master_count" {
  description = "Cantidad de nodos master para HA"
  type        = number
}

variable "worker_count" {
  description = "Cantidad total de nodos worker"
  type        = number
  default     = 6
}

variable "worker_max_pods" {
  description = "Cantidad máxima de pods por nodo worker"
  type        = number
  default     = 7
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

variable "env" {
  description = "Nombre del entorno"
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
