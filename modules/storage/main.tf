resource "random_string" "storage_suffix" {
  count   = var.enable_backup_bucket ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = var.bucket_name_override != null ? var.bucket_name_override : (
    var.enable_backup_bucket ? "${var.project_name}-${var.environment}-backup-${data.aws_caller_identity.current.account_id}-${random_string.storage_suffix[0].result}" : ""
  )
}

# -----------------------------------------------------------------------------
# S3 BACKUP / ARTIFACT BUCKET
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "backup" {
  count         = var.enable_backup_bucket ? 1 : 0
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    var.tags,
    {
      Name        = local.bucket_name
      Environment = var.environment
      Purpose     = "Backup-and-Artifacts"
    }
  )
}

resource "aws_s3_bucket_versioning" "backup" {
  count  = var.enable_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  count  = var.enable_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null ? true : false
  }
}

resource "aws_s3_bucket_public_access_block" "backup" {
  count  = var.enable_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  count  = var.enable_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_expiration_days
    }
  }
}

resource "aws_s3_bucket_policy" "enforce_tls" {
  count  = var.enable_backup_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.backup[0].arn,
          "${aws_s3_bucket.backup[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
          NumericLessThan = {
            "s3:TlsVersion" = "1.2"
          }
        }
      }
    ]
  })
}
