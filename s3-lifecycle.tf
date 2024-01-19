resource "aws_ssm_document" "s3_lifecycle" {
  name            = "ConfigureS3BucketLifecycleRule"
  document_type   = "Automation"
  document_format = "YAML"

  content = templatefile("${path.module}/automations/ConfigureS3BucketLifecycleRule.yaml", {})

}
