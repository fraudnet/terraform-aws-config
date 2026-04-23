data "aws_caller_identity" "current" {
}

# IAM policy doc attached to the SSM remediation role. Grants the S3
# put/lifecycle/tagging actions that the Config rule remediations
# (s3-lifecycle, s3-tags, bucket policy enforcement) execute via SSM
# Automation. Unchanged from the legacy aws-config-role template.
data "template_file" "aws_config_policy" {
  template = file("${path.module}/iam-policies/aws-config-policy.tpl")

  vars = {
    config_logs_bucket = var.config_logs_bucket
    config_logs_prefix = var.config_logs_prefix
    account_id         = data.aws_caller_identity.current.account_id
  }
}

data "aws_iam_policy_document" "remediation-trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "remediation" {
  count              = var.active == true ? 1 : 0
  name               = "aws-config-remediation-role-${var.region}"
  assume_role_policy = data.aws_iam_policy_document.remediation-trust.json
}

resource "aws_iam_policy" "remediation" {
  count  = var.active == true ? 1 : 0
  name   = "aws-config-remediation-policy-${var.region}"
  policy = data.template_file.aws_config_policy.rendered
}

resource "aws_iam_policy_attachment" "remediation" {
  count      = var.active == true ? 1 : 0
  name       = "aws-config-remediation-policy-${var.region}"
  roles      = [aws_iam_role.remediation.0.name]
  policy_arn = aws_iam_policy.remediation.0.arn
}
