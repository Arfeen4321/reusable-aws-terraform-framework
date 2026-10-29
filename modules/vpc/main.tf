# -----------------------------------------------------------------------------
# VPC
# -----------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.vpc_name}"
      Environment = var.environment
    }
  )
}

# -----------------------------------------------------------------------------
# PUBLIC SUBNETS
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = coalesce(each.value.map_public_ip_on_launch, true)

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${each.key}"
      Tier        = "Public"
      Environment = var.environment
    }
  )
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS
# -----------------------------------------------------------------------------
resource "aws_subnet" "private" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${each.key}"
      Tier        = "Private"
      Environment = var.environment
    }
  )
}

# -----------------------------------------------------------------------------
# INTERNET GATEWAY
# -----------------------------------------------------------------------------
resource "aws_internet_gateway" "this" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.vpc_name}-igw"
      Environment = var.environment
    }
  )
}

# -----------------------------------------------------------------------------
# PUBLIC ROUTE TABLE & ASSOCIATIONS
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  count  = length(var.public_subnets) > 0 ? 1 : 0
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this[0].id
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.vpc_name}-public-rt"
      Environment = var.environment
      Tier        = "Public"
    }
  )
}

resource "aws_route_table_association" "public" {
  for_each = var.public_subnets

  subnet_id      = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[0].id
}

# -----------------------------------------------------------------------------
# NAT GATEWAY (OPTIONAL)
# -----------------------------------------------------------------------------
locals {
  public_subnet_keys = sort(keys(var.public_subnets))
  primary_public_key = length(local.public_subnet_keys) > 0 ? local.public_subnet_keys[0] : null

  # Single NAT Gateway map: only first public subnet
  single_nat_map = (var.enable_nat_gateway && var.single_nat_gateway && local.primary_public_key != null) ? {
    (local.primary_public_key) = var.public_subnets[local.primary_public_key]
  } : {}

  # Multi-AZ NAT Gateway map: each public subnet gets a NAT Gateway
  multi_nat_map = (var.enable_nat_gateway && !var.single_nat_gateway) ? var.public_subnets : {}

  active_nat_map = merge(local.single_nat_map, local.multi_nat_map)
}

resource "aws_eip" "nat" {
  for_each   = local.active_nat_map
  domain     = "vpc"
  depends_on = [aws_internet_gateway.this]

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nat-eip-${each.key}"
      Environment = var.environment
    }
  )
}

resource "aws_nat_gateway" "this" {
  for_each = local.active_nat_map

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id
  depends_on    = [aws_internet_gateway.this]

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-nat-gw-${each.key}"
      Environment = var.environment
    }
  )
}

# -----------------------------------------------------------------------------
# PRIVATE ROUTE TABLES & ASSOCIATIONS
# -----------------------------------------------------------------------------
# If single NAT GW: 1 private route table routing to that single NAT GW
# If multi NAT GW: 1 private route table per private subnet routing to the NAT GW in matching AZ
# If no NAT GW: 1 private route table with local routing only
locals {
  create_single_private_rt = length(var.private_subnets) > 0 && (!var.enable_nat_gateway || var.single_nat_gateway)
  create_multi_private_rt  = length(var.private_subnets) > 0 && var.enable_nat_gateway && !var.single_nat_gateway

  # Map AZ to NAT Gateway ID for multi-AZ routing
  az_to_nat_id = {
    for k, v in local.active_nat_map : v.availability_zone => aws_nat_gateway.this[k].id...
  }
}

resource "aws_route_table" "private_single" {
  count  = local.create_single_private_rt ? 1 : 0
  vpc_id = aws_vpc.this.id

  dynamic "route" {
    for_each = var.enable_nat_gateway && length(aws_nat_gateway.this) > 0 ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = values(aws_nat_gateway.this)[0].id
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${var.vpc_name}-private-rt"
      Environment = var.environment
      Tier        = "Private"
    }
  )
}

resource "aws_route_table_association" "private_single" {
  for_each = local.create_single_private_rt ? var.private_subnets : {}

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_single[0].id
}

resource "aws_route_table" "private_multi" {
  for_each = local.create_multi_private_rt ? var.private_subnets : {}
  vpc_id   = aws_vpc.this.id

  dynamic "route" {
    for_each = contains(keys(local.az_to_nat_id), each.value.availability_zone) ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = local.az_to_nat_id[each.value.availability_zone][0]
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${each.key}-rt"
      Environment = var.environment
      Tier        = "Private"
    }
  )
}

resource "aws_route_table_association" "private_multi" {
  for_each = local.create_multi_private_rt ? var.private_subnets : {}

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private_multi[each.key].id
}

# -----------------------------------------------------------------------------
# S3 GATEWAY ENDPOINT (ZERO-COST ROUTING TO S3 FOR PRIVATE SUBNETS)
# -----------------------------------------------------------------------------
data "aws_region" "current" {}

locals {
  private_route_table_ids = local.create_single_private_rt ? [aws_route_table.private_single[0].id] : [for rt in aws_route_table.private_multi : rt.id]
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint && length(var.private_subnets) > 0 ? 1 : 0
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = local.private_route_table_ids

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-s3-gateway-endpoint"
      Environment = var.environment
    }
  )
}

# -----------------------------------------------------------------------------
# OPTIONAL SSM INTERFACE ENDPOINTS (FOR PRIVATE AIR-GAPPED SUBNETS)
# -----------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  count       = var.enable_ssm_endpoints && length(var.private_subnets) > 0 ? 1 : 0
  name_prefix = "${var.environment}-vpce-sg-"
  description = "Security group for VPC Interface Endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-vpce-sg"
      Environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  ssm_services = ["ssm", "ssmmessages", "ec2messages"]
  private_subnet_ids = [for s in aws_subnet.private : s.id]
}

resource "aws_vpc_endpoint" "ssm" {
  for_each = var.enable_ssm_endpoints && length(var.private_subnets) > 0 ? toset(local.ssm_services) : toset([])

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.name}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [aws_security_group.vpc_endpoints[0].id]
  private_dns_enabled = true

  tags = merge(
    var.tags,
    {
      Name        = "${var.environment}-${each.key}-endpoint"
      Environment = var.environment
    }
  )
}
