variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "role_name_prefix" {
  description = "Prefix for IAM role and instance profile name."
  type        = string
  default     = "ec2-instance"
}

variable "enable_ssm" {
  description = "Attach AmazonSSMManagedInstanceCore policy to allow AWS SSM Session Manager access without open SSH ports."
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Attach CloudWatchAgentServerPolicy for extended metric and log shipping."
  type        = bool
  default     = false
}

variable "custom_policy_json" {
  description = "Optional custom IAM policy JSON to attach to the EC2 role (e.g., for S3 application bucket access)."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to IAM resources."
  type        = map(string)
  default     = {}
}
