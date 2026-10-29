variable "aws_region" {
  description = "AWS region for provisioning the Terraform state backend infrastructure."
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.aws_region))
    error_message = "The aws_region variable must follow standard AWS region format (e.g., ap-south-1, us-east-1)."
  }
}

variable "project_name" {
  description = "Project identifier used in naming the remote state bucket and DynamoDB lock table."
  type        = string
  default     = "iac-framework"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "project_name must contain only lowercase alphanumeric characters and hyphens."
  }
}

variable "force_destroy" {
  description = "Whether to allow force-destroying the state S3 bucket (set to false for production safety)."
  type        = bool
  default     = false
}

variable "kms_key_arn" {
  description = "Optional KMS Key ARN to use for S3 SSE-KMS encryption. If null, AES256 (SSE-S3) is used."
  type        = string
  default     = null
}

variable "tags" {
  description = "Resource tags applied to bootstrap backend infrastructure."
  type        = map(string)
  default = {
    Owner     = "DevOps-Team"
    Component = "Terraform-Remote-State"
  }
}
