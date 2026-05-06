terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    #bucket  = "jquinterov.seminario2"
    bucket  = "s3-duna-servicios"
    key     = "Duna/k3s/terraform.tfstate"
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
  region  = "us-east-1"
  profile = "default"
}
