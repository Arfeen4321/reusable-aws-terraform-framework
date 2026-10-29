variable "vpc_id" {
  description = "VPC ID where the security group will be created."
  type        = string
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "security_group_name" {
  description = "Name for the security group."
  type        = string
  default     = "ec2-node"
}

variable "description" {
  description = "Description for the security group."
  type        = string
  default     = "Security group managed by Terraform with least-privilege rules"
}

variable "ingress_rules" {
  description = "List of ingress rule objects defining permitted incoming traffic."
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

variable "egress_rules" {
  description = "List of egress rule objects defining permitted outgoing traffic. Defaults to least privilege outbound."
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
      description = "Allow HTTPS outbound for OS updates, AWS API, and SSM"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "Allow HTTP outbound for package repository mirrors"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "tags" {
  description = "Tags to apply to security group resources."
  type        = map(string)
  default     = {}
}
