# -----------------------------------------------------------------------------
# SECURITY GROUP
# -----------------------------------------------------------------------------
resource "aws_security_group" "this" {
  name_prefix = "${var.environment}-${var.security_group_name}-"
  description = var.description
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description     = lookup(ingress.value, "description", null)
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      cidr_blocks     = lookup(ingress.value, "cidr_blocks", null)
      security_groups = lookup(ingress.value, "security_groups", null)
      self            = lookup(ingress.value, "self", false)
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description     = lookup(egress.value, "description", null)
      from_port       = egress.value.from_port
      to_port         = egress.value.to_port
      protocol        = egress.value.protocol
      cidr_blocks     = lookup(egress.value, "cidr_blocks", null)
      security_groups = lookup(egress.value, "security_groups", null)
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.security_group_name}"
      Environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
