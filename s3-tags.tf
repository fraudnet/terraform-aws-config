resource "aws_ssm_document" "s3_tags" {
  name            = "ConfigureS3BucketTags"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/automations/ConfigureS3BucketTags.yaml", {})

}


resource "aws_config_config_rule" "s3-bucket-tags" {
  count       = var.active == true ? 1 : 0
  name        = "s3-bucket-tags-check"
  description = "Checks that your S3 buckets have tags"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  scope {
    compliance_resource_types = ["AWS::S3::Bucket"]
  }
  
  
  input_parameters= <<EOF
{
	"tag1Key": "cost"
}
EOF

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_remediation_configuration" "s3-bucket-tags" {
  count            = var.active == true  ? 1 : 0 # && var.region != "ap-northeast-3" ? 1 : 0
  config_rule_name = aws_config_config_rule.s3-bucket-tags[0].name
  resource_type    = "AWS::S3::Bucket"
  target_type      = "SSM_DOCUMENT"
  target_id        = aws_ssm_document.s3_tags.name
  target_version = "$DEFAULT"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-config-role-${var.region}"
  }
  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
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