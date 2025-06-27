terraform {
  backend "s3" {}
}
# Provider configuration for member accounts
provider "aws" {
  region = "eu-west-2"
  alias  = "member"
}

# Define the BreakGlassAdminRole
resource "aws_iam_role" "break_glass_admin_role" {
  provider = aws.member
  name     = "BreakGlassAdminRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Principal" : {
        "AWS": [
            "arn:aws:iam::1234:user/break-glass-user",  # Management account break-glass user
            "arn:aws:iam::1234:root",  # Root user of the management account
            "arn:aws:iam::4321:user/break-glass-user",  # SecurityTools account break-glass user
            "arn:aws:iam::4321:root"  # Root user of the SecurityTools account
          ]
      },
      "Action" : "sts:AssumeRole"
    }]
  })
    tags = {
    map-migrate = "Yup"
  }
}

# Attach policies to the break-glass role
resource "aws_iam_role_policy_attachment" "break_glass_admin_policy" {
  provider    = aws.member
  role        = aws_iam_role.break_glass_admin_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AdministratorAccess"
}
resource "aws_iam_role_policy_attachment" "break_glass_org_policy" {
  provider    = aws.member
  role        = aws_iam_role.break_glass_admin_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AWSOrganizationsFullAccess"
}
resource "aws_iam_role_policy_attachment" "break_glass_iam_policy" {
  provider    = aws.member
  role        = aws_iam_role.break_glass_admin_role.name
  policy_arn  = "arn:aws:iam::aws:policy/IAMFullAccess"
}
resource "aws_iam_role_policy_attachment" "break_glass_sso_policy" {
  provider    = aws.member
  role        = aws_iam_role.break_glass_admin_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AWSSSOMasterAccountAdministrator"
}
resource "aws_iam_role_policy_attachment" "break_glass_sso1_policy" {
  provider    = aws.member
  role        = aws_iam_role.break_glass_admin_role.name
  policy_arn  = "arn:aws:iam::aws:policy/AWSSSOMemberAccountAdministrator"
}
