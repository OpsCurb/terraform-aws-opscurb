output "role_arn" {
  description = "Backward-compatible alias for the core scan role ARN."
  value       = aws_iam_role.core_scan.arn
}

output "core_role_arn" {
  description = "ARN of the required core scan role."
  value       = aws_iam_role.core_scan.arn
}

output "core_role_name" {
  description = "Name of the required core scan role."
  value       = aws_iam_role.core_scan.name
}

output "connected_capabilities" {
  description = "Capabilities represented by the created roles."
  value = concat(
    ["core_scan"],
    local.normalized_optional_capabilities,
  )
}

output "shared_optional_role_arn" {
  description = "ARN of the shared optional role when optional_role_mode is shared."
  value       = local.shared_optional_enabled ? aws_iam_role.shared_optional[0].arn : null
}

output "optional_role_arns" {
  description = "Capability-to-role ARN mapping for optional add-ons."
  value = local.shared_optional_enabled
    ? {
        for capability in local.normalized_optional_capabilities :
        capability => aws_iam_role.shared_optional[0].arn
      }
    : {
        for capability, role in aws_iam_role.separate_optional :
        capability => role.arn
      }
}

output "optional_external_ids" {
  description = "Capability-to-external-ID mapping for optional add-ons."
  value = local.shared_optional_enabled
    ? {
        for capability in local.normalized_optional_capabilities :
        capability => local.shared_optional_external_id
      }
    : {
        for capability in local.normalized_optional_capabilities :
        capability => local.optional_external_id_by_capability[capability]
      }
}

output "legacy_role_arn" {
  description = "ARN of the optional legacy broad-access migration role."
  value       = var.create_legacy_role ? aws_iam_role.legacy_broad[0].arn : null
}
