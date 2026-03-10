# OpsCurb – Cross-Account IAM Role Module
# Creates a read-only IAM role that OpsCurb can assume to scan your AWS
# account for cost optimization opportunities.

# ── IAM Role ─────────────────────────────────────────────────────────────────

resource "aws_iam_role" "opscurb" {
  name        = var.role_name
  description = "Read-only role for OpsCurb to scan AWS resources for cost optimization"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.opscurb_aws_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = var.role_name
    ManagedBy = "Terraform"
    Purpose   = "OpsCurb"
  })
}

# ── Read-Only Permissions Policy ─────────────────────────────────────────────

resource "aws_iam_policy" "opscurb" {
  name        = "${var.role_name}-policy"
  description = "Read-only permissions for OpsCurb scanners"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ReadOnly"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVolumes",
          "ec2:DescribeSnapshots",
          "ec2:DescribeAddresses",
          "ec2:DescribeInstances",
          "ec2:DescribeImages",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeNatGateways",
          "ec2:DescribeRouteTables",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeManagedPrefixLists",
          "ec2:GetManagedPrefixListEntries",
          "ec2:DescribeVpcs",
          "ec2:DescribeRegions",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeFastSnapshotRestores",
          "ec2:DescribeSubnets"
        ]
        Resource = "*"
      },
      {
        Sid    = "ELBReadOnly"
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetHealth",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "RDSReadOnly"
        Effect = "Allow"
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBSnapshots",
          "rds:ListTagsForResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ReadOnly"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketTagging",
          "s3:ListBucketVersions",
          "s3:ListMultipartUploadParts",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchReadOnly"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:StartQuery",
          "logs:GetQueryResults"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingReadOnly"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRReadOnly"
        Effect = "Allow"
        Action = [
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:GetLifecyclePolicy",
          "ecr:ListImages"
        ]
        Resource = "*"
      },
      {
        Sid    = "LambdaReadOnly"
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECSReadOnly"
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListServices",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMReadOnly"
        Effect = "Allow"
        Action = [
          "iam:ListUsers",
          "iam:ListAccessKeys",
          "iam:GetAccessKeyLastUsed",
          "iam:ListRoles"
        ]
        Resource = "*"
      },
      {
        Sid    = "CostExplorerReadOnly"
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "ce:GetSavingsPlansUtilization",
          "ce:GetSavingsPlansCoverage",
          "ce:GetReservationUtilization",
          "ce:GetReservationCoverage",
          "ce:GetReservationPurchaseRecommendation"
        ]
        Resource = "*"
      },
      {
        Sid    = "TaggingReadOnly"
        Effect = "Allow"
        Action = [
          "tag:GetResources",
          "tag:GetTagKeys",
          "tag:GetTagValues"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudTrailReadOnly"
        Effect = "Allow"
        Action = [
          "cloudtrail:LookupEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.role_name}-policy"
    ManagedBy = "Terraform"
  })
}

resource "aws_iam_role_policy_attachment" "opscurb" {
  role       = aws_iam_role.opscurb.name
  policy_arn = aws_iam_policy.opscurb.arn
}

# ── Opt-in: Tag Write Permissions ────────────────────────────────────────────
# Only created when enable_tag_write = true.
# Allows OpsCurb's Tagging Compliance dashboard to bulk-apply tags on your
# behalf. Review the feature before enabling.

resource "aws_iam_policy" "opscurb_tag_write" {
  count = var.enable_tag_write ? 1 : 0

  name        = "${var.role_name}-tag-write-policy"
  description = "Opt-in: allows OpsCurb to apply tags via the Tagging Compliance Bulk Apply feature"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TaggingWrite"
        Effect = "Allow"
        Action = [
          "tag:TagResources",
          "tag:UntagResources"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name      = "${var.role_name}-tag-write-policy"
    ManagedBy = "Terraform"
    OptIn     = "true"
  })
}

resource "aws_iam_role_policy_attachment" "opscurb_tag_write" {
  count = var.enable_tag_write ? 1 : 0

  role       = aws_iam_role.opscurb.name
  policy_arn = aws_iam_policy.opscurb_tag_write[0].arn
}
