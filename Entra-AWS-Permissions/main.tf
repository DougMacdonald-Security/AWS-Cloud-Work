data "aws_ssoadmin_instances" "current" {}

resource "aws_ssoadmin_permission_set" "permission_sets" {
  for_each         = local.permission_sets
  instance_arn     = one(data.aws_ssoadmin_instances.current.arns)
  name             = each.key
  description      = lookup(each.value, "description", "Azure Managed") 
  session_duration = "PT8H"
}

# Attach inline policies for permission sets
resource "aws_ssoadmin_permission_set_inline_policy" "inline_policies" {
  for_each = {
    for ps_name, ps in local.permission_sets :
    ps_name => ps if ps.inline_policy != null
  }

  instance_arn       = one(data.aws_ssoadmin_instances.current.arns)
  permission_set_arn = aws_ssoadmin_permission_set.permission_sets[each.key].arn
  inline_policy      = each.value.inline_policy
}

# Attach managed policies for permission sets
resource "aws_ssoadmin_managed_policy_attachment" "managed_policies" {
  for_each = {
    for ps in local.permission_sets_with_policies :
    "${ps.permission_set_name}-${replace(ps.managed_policy_arn, ":", "-")}" => ps
  }

  instance_arn       = one(data.aws_ssoadmin_instances.current.arns)
  permission_set_arn = aws_ssoadmin_permission_set.permission_sets[each.value.permission_set_name].arn
  managed_policy_arn = each.value.managed_policy_arn
}
