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

variable "db_instance_class" {
  description   = "DB Instance Class"
  type          = string
}

variable "db_allocated_storage" {
  description   = "DB Allocated Storage"
  type          = number
}

variable "db_password" {
  description = "Master User DB Password"
  type = string
}