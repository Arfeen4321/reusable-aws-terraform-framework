variable "aws_region" {
  description = "The target AWS region."
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.aws_region))
    error_message = "aws_region must follow the standard AWS region format (e.g., ap-south-1)."
  }
}

variable "environment" {
  description = "Target environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging, or prod."
  }
}

variable "project_name" {
  description = "Project identifier."
  type        = string
  default     = "iac-framework"
}

# -----------------------------------------------------------------------------
# VPC CONFIGURATION
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets."
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool, true)
  }))
  default = {
    public-a = {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "ap-south-1a"
    }
  }
}

variable "private_subnets" {
  description = "Map of private subnets."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
  default = {
    private-a = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "ap-south-1a"
    }
    private-b = {
      cidr_block        = "10.0.20.0/24"
      availability_zone = "ap-south-1b"
    }
  }
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Single shared NAT Gateway across subnets for cost reduction."
  type        = bool
  default     = true
}

variable "enable_s3_endpoint" {
  description = "Provision S3 Gateway VPC Endpoint."
  type        = bool
  default     = true
}

variable "enable_ssm_endpoints" {
  description = "Provision SSM Interface Endpoints for fully private subnets."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# SECURITY GROUPS CONFIGURATION
# -----------------------------------------------------------------------------
variable "security_group_ingress_rules" {
  description = "List of ingress rules for the default EC2 security group."
  type = list(object({
    description     = optional(string, "")
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    self            = optional(bool, false)
  }))
  default = [
    {
      description = "Allow internal VPC HTTP traffic"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    },
    {
      description = "Allow internal VPC HTTPS traffic"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}

variable "security_group_egress_rules" {
  description = "List of egress rules for the default EC2 security group."
  type = list(object({
    description     = optional(string, "")
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), ["0.0.0.0/0"])
    security_groups = optional(list(string), [])
  }))
  default = [
    {
      description = "Allow HTTPS outbound"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP outbound"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# -----------------------------------------------------------------------------
# STORAGE CONFIGURATION
# -----------------------------------------------------------------------------
variable "enable_backup_bucket" {
  description = "Provision an encrypted S3 backup bucket."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# EC2 INSTANCE DEFINITIONS (INPUT-DRIVEN)
# -----------------------------------------------------------------------------
variable "instances" {
  description = "Map of instance specifications. Keys are stable instance identifiers (e.g. node-1, node-2)."
  type = map(object({
    instance_type               = string
    os                          = optional(string, "ubuntu")
    ami_id                      = optional(string, null)
    subnet                      = string # Refers to key in public_subnets or private_subnets
    root_volume_gb              = optional(number, 20)
    root_volume_type            = optional(string, "gp3")
    root_volume_encrypted       = optional(bool, true)
    associate_public_ip_address = optional(bool, false)
    enable_monitoring           = optional(bool, false)
    disable_api_termination     = optional(bool, false)
    key_name                    = optional(string, null)
    user_data                   = optional(string, null)
    extra_tags                  = optional(map(string), {})
    additional_ebs_volumes = optional(map(object({
      device_name = string
      size_gb     = number
      type        = optional(string, "gp3")
      encrypted   = optional(bool, true)
      kms_key_id  = optional(string, null)
    })), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.instances : (
        contains(["ubuntu", "amazon-linux", "rhel", "debian", "custom"], coalesce(v.os, "ubuntu"))
      )
    ])
    error_message = "The 'os' attribute must be one of: 'ubuntu', 'amazon-linux', 'rhel', 'debian', or 'custom'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : (
        coalesce(v.root_volume_gb, 20) >= 8
      )
    ])
    error_message = "The 'root_volume_gb' must be at least 8 GB."
  }
}

variable "tags" {
  description = "Additional tags applied to all environment resources."
  type        = map(string)
  default     = {}
}
