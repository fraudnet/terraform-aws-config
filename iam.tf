# Recorder role and SSM remediation role are both owned by the consumer
# (parent module). This module only references their ARNs via
# var.config_role_arn (recorder) and var.remediation_role_arn (SSM).
