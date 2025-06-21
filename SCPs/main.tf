terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
}
terraform {
  backend "s3" {
    bucket         = "s3-tfstate-management-euw2"
    key            = "org/SCP.tfstate"
    region         = "eu-west-2"
    encrypt        = true
  }
}

locals {
  all_json_files = fileset("${path.module}/modules", "*.json")

  statement_paths = [
    for file in local.all_json_files :
    "${path.module}/modules/${file}"
  ]

  scp_statements = [
    for f in local.statement_paths : jsondecode(file(f))
  ]

  scp_policy = {
    Version   = "2012-10-17"
    Statement = local.scp_statements
  }
}

# Get root
data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "root_ous" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}


resource "aws_organizations_policy" "combined_scp" {
  name        = "CombinedSecurityPolicy"
  description = "Auto-assembled SCP from all JSON files"
  content     = jsonencode(local.scp_policy)
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "scp_to_ous" {
  for_each = {
    for ou in data.aws_organizations_organizational_units.root_ous.children :
    ou.id => ou
    if ou.id != "ou-zhuc-1234"
  }

  policy_id = aws_organizations_policy.combined_scp.id
  target_id = each.key
}