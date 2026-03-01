output "role_arn" {
  description = "ARN of the IAM role that OpsCurb will assume. Paste this into your OpsCurb dashboard to complete the account connection."
  value       = aws_iam_role.opscurb.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.opscurb.name
}

output "policy_arn" {
  description = "ARN of the read-only IAM policy attached to the role."
  value       = aws_iam_policy.opscurb.arn
}

