variable "aws_region" { default     = "us-east-1" }
variable "aws_profile" { default = "default" }

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Storage inicial en GB"
  type        = number
  default     = 20
}

variable "target_vpc_id" {
   type        = string
   default     = ""
   description = "VPC ID explícito para evitar ambiguedad en data sources (opcional)"
}

variable "target_worker_sg_id" {
   type        = string
   default     = ""
   description = "Security Group ID del worker para evitar ambiguedad (opcional)"
}

# Secrets
variable "db_password"  {
   type           = string
   sensitive      = true
   description    = "DB password"

}