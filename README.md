# OpsCurb Terraform Module

This module creates the IAM roles used by OpsCurb's tiered AWS access model:

- one required `core_scan` role
- optional add-on roles for `deep_inspect`, `logs_diagnostics`, `s3_inventory`, `iam_inventory`, and `tag_inventory`
- an optional legacy broad-access role for migration support only

The module vendors the generated IAM policy JSON artifacts in this repository so the Terraform roles stay aligned with the shared access manifest and permissions matrix.

## Core-only example

```hcl
module "opscurb" {
  source  = "OpsCurb/opscurb/aws"
  version = "~> 1.0"

  opscurb_aws_account_id = "593543056092"
  external_id            = "ccg-core-12345678"
}

output "role_arn" {
  value = module.opscurb.role_arn
}
```

## Core plus shared optional add-ons

```hcl
module "opscurb" {
  source  = "OpsCurb/opscurb/aws"
  version = "~> 1.0"

  opscurb_aws_account_id = "593543056092"
  external_id            = "ccg-core-12345678"

  optional_role_mode     = "shared"
  optional_capabilities  = ["deep_inspect", "logs_diagnostics", "s3_inventory"]
  optional_external_id   = "ccg-optional-shared-12345678"
}

output "core_role_arn" {
  value = module.opscurb.core_role_arn
}

output "optional_role_arns" {
  value = module.opscurb.optional_role_arns
}
```

## Core plus separate optional add-ons

```hcl
module "opscurb" {
  source  = "OpsCurb/opscurb/aws"
  version = "~> 1.0"

  opscurb_aws_account_id = "593543056092"
  external_id            = "ccg-core-12345678"

  optional_role_mode    = "separate"
  optional_capabilities = ["deep_inspect", "tag_inventory"]
  optional_external_ids = {
    deep_inspect = "ccg-deep-inspect-12345678"
    tag_inventory = "ccg-tag-inventory-12345678"
  }
}
```

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `opscurb_aws_account_id` | `string` | n/a | AWS account ID that OpsCurb uses to assume the roles. |
| `external_id` | `string` | n/a | External ID for the core scan role. |
| `role_name_prefix` | `string` | `"opscurb"` | Prefix used for generated IAM role names. |
| `path` | `string` | `"/"` | IAM path for generated roles. |
| `tags` | `map(string)` | `{}` | Tags applied to all generated roles. |
| `optional_capabilities` | `set(string)` | `[]` | Optional capabilities to create add-on roles for. |
| `optional_role_mode` | `string` | `"separate"` | Use `"shared"` for one merged optional role or `"separate"` for one role per add-on. |
| `optional_external_id` | `string` | `null` | Shared optional-role external ID or fallback for separate roles. |
| `optional_external_ids` | `map(string)` | `{}` | Per-capability external IDs for separate optional roles. |
| `create_legacy_role` | `bool` | `false` | Create the legacy broad-access migration role. |
| `legacy_external_id` | `string` | `null` | External ID for the legacy migration role. Falls back to `external_id`. |

## Outputs

| Name | Description |
| --- | --- |
| `role_arn` | Backward-compatible alias for the core scan role ARN. |
| `core_role_arn` | ARN of the required core scan role. |
| `core_role_name` | Name of the required core scan role. |
| `connected_capabilities` | List of capabilities represented by the created roles. |
| `shared_optional_role_arn` | ARN of the shared optional role when enabled. |
| `optional_role_arns` | Capability-to-role ARN mapping for optional add-ons. |
| `optional_external_ids` | Capability-to-external-ID mapping for optional add-ons. |
| `legacy_role_arn` | ARN of the legacy migration role when enabled. |
