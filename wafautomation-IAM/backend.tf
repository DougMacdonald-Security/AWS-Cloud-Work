terraform {
  backend "s3" {
    bucket = "s3-tfstate-devtest-euw2"
    key    = "WAFDeployment/awswaf_automation_iam.tfstate"
    region = "eu-west-2"
  }
}