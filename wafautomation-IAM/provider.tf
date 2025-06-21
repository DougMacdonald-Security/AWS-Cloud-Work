terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

     random = {
      source = "hashicorp/random"
    }
    }
  }

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-2"
}