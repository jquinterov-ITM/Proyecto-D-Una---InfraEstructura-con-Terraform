terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket  = "jquinterov.seminario2"
    key     = "Duna/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "default"
  }

 /*
  backend "local" {
    path = "terraform.tfstate"
  }
  */
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}
