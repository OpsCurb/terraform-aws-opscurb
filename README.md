# terraform-aws-opscurb

Terraform module that creates the cross-account IAM role required to connect
an AWS account to [OpsCurb](https://opscurb.com).

OpsCurb assumes this role to perform **read-only** scans for idle resources,
aged snapshots, cost anomalies, and tagging compliance — it cannot modify,
delete, or create any resources in your account.

---

## Usage

```hcl
module "opscurb" {
  source  = "OpsCurb/opscurb/aws"
  version = "~> 1.0"

  # Both values are shown in your OpsCurb dashboard under
  # Settings → AWS Accounts → Connect Account
  opscurb_aws_account_id = "123456789012"
  external_id            = "your-external-id-from-dashboard"
}

output "role_arn" {
  value = module.opscurb.role_arn
}
```

After `terraform apply`, copy the `role_arn` output and paste it into the
OpsCurb dashboard to complete the connection.

---

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.3 |
| aws | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `opscurb_aws_account_id` | AWS Account ID of the OpsCurb application (shown in your dashboard) | `string` | — | yes |
| `external_id` | External ID for confused-deputy protection (shown in your dashboard) | `string` | — | yes |
| `role_name` | Name of the IAM role created in your account | `string` | `"OpsCurbRole"` | no |
| `tags` | Additional tags to apply to all resources | `map(string)` | `{}` | no |
| `enable_tag_write` | Grant OpsCurb permission to apply tags via the Bulk Apply feature | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | ARN of the IAM role — paste this into the OpsCurb dashboard |
| `role_name` | Name of the IAM role |
| `policy_arn` | ARN of the read-only policy attached to the role |

---

## Permissions

The module creates a single read-only policy covering:

| Service | Actions |
|---------|---------|
| EC2 | Describe volumes, snapshots, instances, launch templates, flow logs, managed prefix lists, NAT gateways, VPC endpoints, etc. |
| ELB | Describe load balancers, target groups, target health |
| RDS | Describe DB instances and snapshots |
| S3 | List buckets, read metadata (no object content access) |
| CloudWatch / Logs | Get metrics, describe log groups, and run scoped Logs Insights queries for Lambda and NAT evidence |
| ECR | Describe repositories and images |
| Lambda | List and describe functions |
| ECS | List clusters/services and read task definitions for Fargate waste detection |
| IAM | List users, access keys, and roles to detect stale credentials |
| Cost Explorer | Get cost, forecast, savings plans, and reservation data |
| Resource Groups Tagging | Read-only tag scanning |

**OpsCurb cannot read S3 object contents, write data, or delete anything.**

Some of these read permissions exist to improve scan precision rather than widen access. For example, launch-template and Auto Scaling reads help OpsCurb avoid false positives on stale AMIs, `logs:StartQuery` / `logs:GetQueryResults` let OpsCurb inspect Lambda `REPORT` lines and existing VPC Flow Logs for higher-confidence waste findings, and ECS reads let OpsCurb size Fargate services from task definitions plus ECS service telemetry.

### Optional: Tag Write

Set `enable_tag_write = true` to allow OpsCurb's Tagging Compliance dashboard
to bulk-apply tags on your behalf. This attaches a second policy with
`tag:TagResources` and `tag:UntagResources`.

---

## Security

- **Confused-deputy protection**: the trust policy requires a unique `external_id`
  that is generated per-account in your dashboard. This prevents any third party
  from tricking OpsCurb into assuming your role even if they know your account ID.
- **Least privilege**: all permissions are read-only. The only optional write
  permission is tagging, and it is disabled by default.
- **Versioned**: pin to a specific module version to avoid unexpected permission
  changes during upgrades.

---

## License

Apache 2.0 — see [LICENSE](LICENSE).

