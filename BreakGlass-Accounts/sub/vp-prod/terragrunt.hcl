include {
  path = find_in_parent_folders()
}

terraform {
  source = "../_module"
}

remote_state {
  backend = "s3"
  config = {
    bucket         = "s3-tfstate-veripark-prod-euw2"
    key            = "iam/breakglass_role.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}
