provider "aws" {
  region = "eu-west-2"
}
terraform {
  backend "s3" {
    bucket          = "terraform-root-account"
    key               = "iam/entra_id.tfstate"
    region           = "eu-west-2"
  }
}
