variable "vpc_id" {
  description   = "VPC ID"
  type          = string
}

variable "subnet_ids" {
  description   = "Subnet IDs List"
  type          = list(string)
}

variable "worker_sg_id" {
  description   = "Worker Security Group ID"
  type          = string
}