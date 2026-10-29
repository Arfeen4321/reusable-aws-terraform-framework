output "state_bucket_name" {
  description = "Name of the S3 bucket created for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.id
}

output "state_bucket_arn" {
  description = "ARN of the S3 bucket created for Terraform remote state."
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_lock_table_name" {
  description = "Name of the DynamoDB table created for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_lock_table_arn" {
  description = "ARN of the DynamoDB table created for Terraform state locking."
  value       = aws_dynamodb_table.terraform_locks.arn
}

output "aws_region" {
  description = "AWS region where remote backend infrastructure resides."
  value       = var.aws_region
}

output "backend_config_snippet" {
  description = "Terraform backend configuration snippet for environment main.tf or backend-config.hcl."
  value = <<-EOT
    # S3 Remote Backend Configuration
    terraform {
      backend "s3" {
        bucket         = "${aws_s3_bucket.terraform_state.id}"
        key            = "environments/<env>/terraform.tfstate"
        region         = "${var.aws_region}"
        dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
        encrypt        = true
      }
    }
  EOT
}
