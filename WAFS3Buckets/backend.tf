terraform {
  backend "s3" {
    bucket = "s3-tfstate-production-euw2"
    key    = "WAFDeployment/awswaf_s3.tfstate"
    region = "eu-west-2"
  }
}