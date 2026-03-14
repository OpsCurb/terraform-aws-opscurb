locals {
  policy_file_by_capability = {
    core_scan        = "permissions-policy.core-scan.json"
    deep_inspect     = "permissions-policy.deep-inspect.json"
    logs_diagnostics = "permissions-policy.logs-diagnostics.json"
    s3_inventory     = "permissions-policy.s3-inventory.json"
    iam_inventory    = "permissions-policy.iam-inventory.json"
    tag_inventory    = "permissions-policy.tag-inventory.json"
    legacy_broad     = "permissions-policy.legacy.json"
  }

  normalized_optional_capabilities = sort(tolist(var.optional_capabilities))
  separate_optional_capabilities   = var.optional_role_mode == "separate" ? toset(local.normalized_optional_capabilities) : toset([])
  shared_optional_enabled          = var.optional_role_mode == "shared" && length(local.normalized_optional_capabilities) > 0

  policy_json_by_capability = {
    for capability, relative_path in local.policy_file_by_capability :
    capability => file("${path.module}/${relative_path}")
  }

  shared_optional_external_id = (
    var.optional_external_id != null && trimspace(var.optional_external_id) != ""
    ? trimspace(var.optional_external_id)
    : trimspace(var.external_id)
  )

  legacy_external_id_value = (
    var.legacy_external_id != null && trimspace(var.legacy_external_id) != ""
    ? trimspace(var.legacy_external_id)
    : trimspace(var.external_id)
  )

  optional_external_id_by_capability = {
    for capability in local.normalized_optional_capabilities :
    capability => (
      trimspace(lookup(var.optional_external_ids, capability, "")) != ""
      ? trimspace(lookup(var.optional_external_ids, capability, ""))
      : (
        var.optional_external_id != null && trimspace(var.optional_external_id) != ""
        ? trimspace(var.optional_external_id)
        : trimspace(var.external_id)
      )
    )
  }

  core_role_name            = "${var.role_name_prefix}-core-scan"
  shared_optional_role_name = "${var.role_name_prefix}-optional"
  legacy_role_name          = "${var.role_name_prefix}-legacy"
}

data "aws_iam_policy_document" "core_assume_role" {
  statement {
    sid     = "AllowOpsCurbAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${trimspace(var.opscurb_aws_account_id)}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [trimspace(var.external_id)]
    }
  }
}

data "aws_iam_policy_document" "shared_optional_assume_role" {
  count = local.shared_optional_enabled ? 1 : 0

  statement {
    sid     = "AllowOpsCurbAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${trimspace(var.opscurb_aws_account_id)}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.shared_optional_external_id]
    }
  }
}

data "aws_iam_policy_document" "separate_optional_assume_role" {
  for_each = local.separate_optional_capabilities

  statement {
    sid     = "AllowOpsCurbAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${trimspace(var.opscurb_aws_account_id)}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.optional_external_id_by_capability[each.key]]
    }
  }
}

data "aws_iam_policy_document" "legacy_assume_role" {
  count = var.create_legacy_role ? 1 : 0

  statement {
    sid     = "AllowOpsCurbAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${trimspace(var.opscurb_aws_account_id)}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.legacy_external_id_value]
    }
  }
}

data "aws_iam_policy_document" "shared_optional_permissions" {
  count = local.shared_optional_enabled ? 1 : 0

  source_policy_documents = [
    for capability in local.normalized_optional_capabilities :
    local.policy_json_by_capability[capability]
  ]
}

resource "aws_iam_role" "core_scan" {
  name               = local.core_role_name
  path               = var.path
  assume_role_policy = data.aws_iam_policy_document.core_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "core_scan" {
  name   = "${local.core_role_name}-policy"
  role   = aws_iam_role.core_scan.id
  policy = local.policy_json_by_capability.core_scan
}

resource "aws_iam_role" "shared_optional" {
  count              = local.shared_optional_enabled ? 1 : 0
  name               = local.shared_optional_role_name
  path               = var.path
  assume_role_policy = data.aws_iam_policy_document.shared_optional_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "shared_optional" {
  count  = local.shared_optional_enabled ? 1 : 0
  name   = "${local.shared_optional_role_name}-policy"
  role   = aws_iam_role.shared_optional[0].id
  policy = data.aws_iam_policy_document.shared_optional_permissions[0].json
}

resource "aws_iam_role" "separate_optional" {
  for_each = local.separate_optional_capabilities

  name               = "${var.role_name_prefix}-${replace(each.key, "_", "-")}"
  path               = var.path
  assume_role_policy = data.aws_iam_policy_document.separate_optional_assume_role[each.key].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "separate_optional" {
  for_each = local.separate_optional_capabilities

  name   = "${var.role_name_prefix}-${replace(each.key, "_", "-")}-policy"
  role   = aws_iam_role.separate_optional[each.key].id
  policy = local.policy_json_by_capability[each.key]
}

resource "aws_iam_role" "legacy_broad" {
  count              = var.create_legacy_role ? 1 : 0
  name               = local.legacy_role_name
  path               = var.path
  assume_role_policy = data.aws_iam_policy_document.legacy_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy" "legacy_broad" {
  count  = var.create_legacy_role ? 1 : 0
  name   = "${local.legacy_role_name}-policy"
  role   = aws_iam_role.legacy_broad[0].id
  policy = local.policy_json_by_capability.legacy_broad
}
