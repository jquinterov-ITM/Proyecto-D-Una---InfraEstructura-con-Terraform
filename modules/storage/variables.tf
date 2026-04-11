variable "env" {
  description = "Entorno (dev, stg, prod)"
  type        = string
}

variable "bucket_name" {
  description = "Nombre del bucket S3 para almacenamiento de assets"
  type        = string
}

variable "cors_allowed_origins" {
  description = "Lista de origenes permitidos en la regla CORS del bucket"
  type        = list(string)
  default     = ["*"]
}
