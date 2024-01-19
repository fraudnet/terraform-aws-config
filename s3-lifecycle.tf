resource "aws_ssm_document" "s3_lifecycle" {
  name            = "ConfigureS3BucketLifecycleRule"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/automations/ConfigureS3BucketLifecycleRule.yaml", {})

}

resource "aws_config_config_rule" "s3-bucket-expiration" {
  count       = var.active == true ? 1 : 0
  name        = "s3-lifecycle-policy-check"
  description = "Checks that your S3 buckets have lifecycle policy."

  source {
    owner             = "AWS"
    source_identifier = "S3_LIFECYCLE_POLICY_CHECK"
  }

  depends_on = [aws_config_configuration_recorder.main]
}



resource "aws_config_remediation_configuration" "s3-bucket-expiration" {
  count            = var.active == true && var.region != "ap-northeast-3" ? 1 : 0
  config_rule_name = aws_config_config_rule.s3-bucket-expiration[0].name
  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.s3_lifecycle.name
  target_version = "$DEFAULT"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-config-role-${var.region}"
  }
  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }
  parameter {
    name         = "NoncurrentDays"
    static_value = 90
  }

  automatic                  = true
  maximum_automatic_attempts = 5
  retry_attempt_seconds      = 600

  execution_controls {
    ssm_controls {
      concurrent_execution_rate_percentage = 10
      error_percentage                     = 20
    }
  }
}