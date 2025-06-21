
# Load group permissions mapping
variable "group_permissions" {
  type = map(object({
    permission_set_arn = string
    account_id         = string
  }))
}

# Lookup the Entra ID provisioned groups dynamically
data "aws_identitystore_group" "identity_groups" {
  for_each          = var.group_permissions
  identity_store_id = one(data.aws_ssoadmin_instances.current.identity_store_ids)  # Get Identity Store ID
  
  alternate_identifier {
    unique_attribute {
    attribute_path  = "DisplayName"
    attribute_value = each.key  # Group name from var.group_permissions
  }
  }
}

# Assign permission sets to groups in accounts
resource "aws_ssoadmin_account_assignment" "account_assignments" {
  for_each          = var.group_permissions
  instance_arn      = one(data.aws_ssoadmin_instances.current.arns)  # Get SSO Instance ARN
  permission_set_arn = each.value.permission_set_arn
  principal_id      = data.aws_identitystore_group.identity_groups[each.key].group_id  # Use dynamically fetched group_id
  principal_type    = "GROUP"
  target_id        = each.value.account_id
  target_type      = "AWS_ACCOUNT"
}
