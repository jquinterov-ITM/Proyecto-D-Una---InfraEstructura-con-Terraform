terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }

  # Descomentar y configurar si necesitas un backend remoto
  # backend "s3" {
  #   bucket         = "Proyecto_D-Una-Terraform-State"
  #   key            = "laboratorio1/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  #   profile         = "PSeminario"
  # }

}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}
