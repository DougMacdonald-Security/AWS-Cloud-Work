# Get the currently authenticated AWS Account ID
data "aws_caller_identity" "current" {}

# Map account-specific S3 backend configurations
variable "backend_config" {
  type = map(object({
    bucket = string
  }))
  default = {
    "339713012643" = { bucket = "s3-tfstate-audit-euw2" }
    "381492148168" = { bucket = "s3-tfstate-backup-euw2"}
    "381491825821" = { bucket = "s3-tfstate-devtest-euw2" }
    "851725432165" = { bucket = "s3-tfstate-log-archive-euw2"}
    "211125625664" = { bucket = "s3-tfstate-network-euw2" }
    "713881793836" = { bucket = "s3-tfstate-operations-dev-euw2"}
    "207567780569" = { bucket = "s3-tfstate-operations-prod-euw2" }
    "533267118313" = { bucket = "s3-tfstate-production-euw2"}
    "533267216364" = { bucket = "s3-tfstate-sharedservices-euw2" }
    "010928204689" = { bucket = "s3-tfstate-veripark-dev-euw2"}
    "010928204850" = { bucket = "s3-tfstate-veripark-prod-euw2" }
  }
}

# Lookup the current account’s backend configuration
locals {
  current_account_id = data.aws_caller_identity.current.account_id
  current_backend    = lookup(var.backend_config, local.current_account_id, null)
}

# Configure Terraform Backend
terraform {
  backend "s3" {
    bucket         = local.current_backend.bucket
    key            = "iam/breakglass_role.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

# Provider configuration for a member account
provider "aws" {
  region = "eu-west-2"
  alias  = "member"
}

# Define the BreakGlassAdminRole in each member account
resource "aws_iam_role" "break_glass_admin_role" {
  provider = aws.member
  name     = "BreakGlassAdminRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "AWS": [
            "arn:aws:iam::654654512313:user/break-glass-user",  # Management account break-glass user
            "arn:aws:iam::654654512313:root",  # Root user of the management account
            "arn:aws:iam::891377009330:user/break-glass-user",  # SecurityTools account break-glass user
            "arn:aws:iam::891377009330:root"  # Root user of the SecurityTools account
          ]
      },
      "Action" : "sts:AssumeRole"
    }]
  })
}

# Attach Administrator Access Policy to the break-glass role (adjust to least privilege)
resource "aws_iam_role_policy_attachment" "break_glass_admin_policy" {
  provider    = aws.member
  role        = aws_iam_role.break_glass_admin_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
}
