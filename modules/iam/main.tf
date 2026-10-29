# -----------------------------------------------------------------------------
# IAM ROLE FOR EC2 INSTANCES
# -----------------------------------------------------------------------------
resource "aws_iam_role" "this" {
  name_prefix = "${var.environment}-${var.role_name_prefix}-"
  description = "IAM role for ${var.environment} EC2 instances managed by Terraform"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.role_name_prefix}-role"
      Environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Attach AWS SSM Managed Policy (Secure, port-less remote access)
resource "aws_iam_role_policy_attachment" "ssm" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent Policy (Optional)
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Optional Custom Inline Policy (e.g. S3 Backup access)
resource "aws_iam_role_policy" "custom" {
  count       = var.custom_policy_json != null ? 1 : 0
  name_prefix = "${var.environment}-custom-policy-"
  role        = aws_iam_role.this.id
  policy      = var.custom_policy_json
}

# -----------------------------------------------------------------------------
# IAM INSTANCE PROFILE
# -----------------------------------------------------------------------------
resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.environment}-${var.role_name_prefix}-profile-"
  role        = aws_iam_role.this.name

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.role_name_prefix}-profile"
      Environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
