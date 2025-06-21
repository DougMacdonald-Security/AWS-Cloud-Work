terraform {
  backend "s3" {
    bucket = "s3-tfstate-production-euw1"
    key    = "WAFDeployment/awswaf_deployment.tfstate"
    region = "eu-west-1"
  }
}