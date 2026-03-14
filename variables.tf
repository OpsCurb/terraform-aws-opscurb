variable "opscurb_aws_account_id" {
  description = "AWS account ID that OpsCurb uses to assume the customer-facing roles."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", trimspace(var.opscurb_aws_account_id)))
    error_message = "opscurb_aws_account_id must be a 12-digit AWS account ID."
  }
}

variable "external_id" {
  description = "External ID for the required core scan role."
  type        = string

  validation {
    condition     = length(trimspace(var.external_id)) > 0
    error_message = "external_id must not be empty."
  }
}

variable "role_name_prefix" {
  description = "Prefix used for generated IAM role names."
  type        = string
  default     = "opscurb"
}

variable "path" {
  description = "IAM path for created roles."
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags applied to every created IAM role."
  type        = map(string)
  default     = {}
}

variable "optional_capabilities" {
  description = "Optional add-on capabilities to create roles for."
  type        = set(string)
  default     = []

  validation {
    condition = alltrue([
      for capability in var.optional_capabilities :
      contains([
        "deep_inspect",
        "logs_diagnostics",
        "s3_inventory",
        "iam_inventory",
        "tag_inventory",
      ], capability)
    ])
    error_message = "optional_capabilities may only include deep_inspect, logs_diagnostics, s3_inventory, iam_inventory, or tag_inventory."
  }
}

variable "optional_role_mode" {
  description = "Whether optional capabilities use one shared role or separate roles."
  type        = string
  default     = "separate"

  validation {
    condition     = contains(["shared", "separate"], var.optional_role_mode)
    error_message = "optional_role_mode must be either shared or separate."
  }
}

variable "optional_external_id" {
  description = "External ID for the shared optional role, or a fallback when separate optional roles do not have explicit IDs."
  type        = string
  default     = null
  nullable    = true
}

variable "optional_external_ids" {
  description = "Per-capability external IDs for separate optional roles."
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for external_id in values(var.optional_external_ids) :
      length(trimspace(external_id)) > 0
    ])
    error_message = "optional_external_ids values must not be empty or whitespace-only."
  }
}

variable "create_legacy_role" {
  description = "Whether to create the legacy broad-access migration role."
  type        = bool
  default     = false
}

variable "legacy_external_id" {
  description = "External ID for the optional legacy broad-access migration role. Falls back to external_id when omitted."
  type        = string
  default     = null
  nullable    = true
}
