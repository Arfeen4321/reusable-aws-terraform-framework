variable "aws_region" {
  description = "The target AWS region."
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-\\d$", var.aws_region))
    error_message = "aws_region must follow the standard AWS region format."
  }
}

variable "environment" {
  description = "Target environment name."
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Project identifier."
  type        = string
  default     = "iac-framework"
}

variable "vpc_cidr" {
  description = "VPC CIDR block."
  type        = string
  default     = "10.1.0.0/16"
}

variable "public_subnets" {
  description = "Map of public subnets."
  type = map(object({
    cidr_block              = string
    availability_zone       = string
    map_public_ip_on_launch = optional(bool, true)
  }))
}

variable "private_subnets" {
  description = "Map of private subnets."
  type = map(object({
    cidr_block        = string
    availability_zone = string
  }))
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets."
  type        = bool
  default     = true
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
  description = "Provision SSM Interface Endpoints."
  type        = bool
  default     = false
}

variable "security_group_ingress_rules" {
  description = "List of ingress rules."
  type = list(object({
    description     = optional(string, "")
    from_port       = number
    to_port         = number
    protocol        = string
    cidr_blocks     = optional(list(string), [])
    security_groups = optional(list(string), [])
    self            = optional(bool, false)
  }))
  default = []
}

variable "security_group_egress_rules" {
  description = "List of egress rules."
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

variable "enable_backup_bucket" {
  description = "Provision an encrypted S3 backup bucket."
  type        = bool
  default     = true
}

variable "instances" {
  description = "Map of instance specifications."
  type = map(object({
    instance_type               = string
    os                          = optional(string, "ubuntu")
    ami_id                      = optional(string, null)
    subnet                      = string
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
}

variable "tags" {
  description = "Additional tags applied to all environment resources."
  type        = map(string)
  default     = {}
}
