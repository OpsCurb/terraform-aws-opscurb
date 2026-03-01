variable "opscurb_aws_account_id" {
  description = "AWS Account ID of the OpsCurb application (the account that will assume this role). Copy this value from your OpsCurb dashboard."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.opscurb_aws_account_id))
    error_message = "opscurb_aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  description = "External ID for the confused-deputy protection on the trust policy. Copy this value from your OpsCurb dashboard."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.external_id) >= 8
    error_message = "external_id must be at least 8 characters long."
  }
}

variable "role_name" {
  description = "Name of the IAM role created in your AWS account."
  type        = string
  default     = "OpsCurbRole"
}

variable "tags" {
  description = "Additional tags to apply to all resources created by this module."
  type        = map(string)
  default     = {}
}

variable "enable_tag_write" {
  description = <<-EOT
    Opt-in: grant OpsCurb permission to apply tags on your behalf via the
    Tagging Compliance dashboard's Bulk Apply feature.

    When true, an additional IAM policy is attached to the role that allows
    tag:TagResources and tag:UntagResources across all resources.
    The base read-only policy always includes tag:GetResources (required
    for the compliance scanner).

    Set to true only after reviewing the Tagging Compliance feature and
    confirming you want OpsCurb to write tags to your resources.
  EOT
  type        = bool
  default     = false
}

