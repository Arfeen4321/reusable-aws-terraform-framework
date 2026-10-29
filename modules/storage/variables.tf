variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "project_name" {
  description = "Project name identifier."
  type        = string
  default     = "iac-framework"
}

variable "enable_backup_bucket" {
  description = "Whether to provision an encrypted S3 bucket for application backups and artifacts."
  type        = bool
  default     = false
}

variable "bucket_name_override" {
  description = "Custom S3 bucket name. If null, an auto-generated unique name will be used."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Optional KMS Key ARN for S3 SSE-KMS encryption. If null, AES256 (SSE-S3) is used."
  type        = string
  default     = null
}

variable "versioning_enabled" {
  description = "Enable versioning on the backup bucket."
  type        = bool
  default     = true
}

variable "lifecycle_expiration_days" {
  description = "Number of days after which noncurrent object versions expire."
  type        = number
  default     = 90
}

variable "force_destroy" {
  description = "Whether to allow force-destroying the bucket for teardown testing."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to storage resources."
  type        = map(string)
  default     = {}
}
