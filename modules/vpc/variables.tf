variable "vpc_cidr" {
  description = "The IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod", "sandbox", "test"], var.environment)
    error_message = "environment must be one of: dev, staging, prod, sandbox, test."
  }
}

variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
  default     = "main"
}

variable "public_subnets" {
  description = "Map of public subnet configurations. Keys should be descriptive names such as 'public-a', 'public-b'."
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool, true)
  }))
  default = {}
}

variable "private_subnets" {
  description = "Map of private subnet configurations. Keys should be descriptive names such as 'private-a', 'private-b'."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {}
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC."
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets outbound internet access."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "If true, provision a single NAT Gateway shared across private subnets (cost optimization). If false, provision one per public subnet AZ."
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Provision a Gateway VPC Endpoint for S3 to route private traffic directly to S3 without internet/NAT costs."
  type        = bool
  default     = true
}

variable "enable_ssm_endpoints" {
  description = "Provision Interface VPC Endpoints for AWS Systems Manager (ssm, ssmmessages, ec2messages) for air-gapped private subnets."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all VPC resources."
  type        = map(string)
  default     = {}
}
