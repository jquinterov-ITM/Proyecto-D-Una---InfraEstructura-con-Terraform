terraform {
  #required_version = ">= 1.0"
  required_version = ">= 1.5.0"

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

  /*
  backend "s3" {
    bucket  = "gduqueo.vseminario2profundizacion"
    key     = "laboratorio1/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "VSeminario"
  }
*/

}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      Environment = terraform.workspace
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}
