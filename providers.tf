terraform {
    
  cloud {
    organization = "olezaiven"
    workspaces {
      name = "terraform-hello-world"
    }
  }


  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}
