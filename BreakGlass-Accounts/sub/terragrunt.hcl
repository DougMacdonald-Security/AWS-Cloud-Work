# Define the remote state backend for Terraform
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket         = "terraform-state-placeholder"
    key            = "${path_relative_to_include()}/iam/breakglass_role.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

# Automatically fetch credentials based on the AWS profile
inputs = {
  role_name = "BreakGlassAdminRole"
}
