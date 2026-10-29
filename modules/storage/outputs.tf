output "backup_bucket_name" {
  description = "Name of the provisioned backup/artifacts S3 bucket."
  value       = var.enable_backup_bucket ? aws_s3_bucket.backup[0].id : null
}

output "backup_bucket_arn" {
  description = "ARN of the provisioned backup/artifacts S3 bucket."
  value       = var.enable_backup_bucket ? aws_s3_bucket.backup[0].arn : null
}

output "backup_bucket_domain_name" {
  description = "Bucket domain name of the provisioned backup/artifacts S3 bucket."
  value       = var.enable_backup_bucket ? aws_s3_bucket.backup[0].bucket_domain_name : null
}
