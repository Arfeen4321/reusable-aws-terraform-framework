variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string
}

variable "instances" {
  description = "Map of instance specifications. Keys are stable instance identifiers (e.g., node-1, node-2, web-primary)."
  type = map(object({
    instance_type               = string
    os                          = optional(string, "ubuntu")
    ami_id                      = optional(string, null)
    subnet_id                   = string
    associate_public_ip_address = optional(bool, false)
    root_volume_size            = optional(number, 20)
    root_volume_type            = optional(string, "gp3")
    root_volume_encrypted       = optional(bool, true)
    root_kms_key_id             = optional(string, null)
    enable_monitoring           = optional(bool, false)
    iam_instance_profile        = optional(string, null)
    security_group_ids          = optional(list(string), [])
    disable_api_termination     = optional(bool, false)
    user_data                   = optional(string, null)
    user_data_base64            = optional(string, null)
    key_name                    = optional(string, null)
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
        coalesce(v.root_volume_size, 20) >= 8
      )
    ])
    error_message = "The 'root_volume_size' must be at least 8 GB."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : (
        contains(["gp2", "gp3", "io1", "io2", "st1", "sc1"], coalesce(v.root_volume_type, "gp3"))
      )
    ])
    error_message = "The 'root_volume_type' must be one of: 'gp2', 'gp3', 'io1', 'io2', 'st1', 'sc1'."
  }

  validation {
    condition = alltrue([
      for k, v in var.instances : (
        v.os != "custom" || (v.os == "custom" && v.ami_id != null)
      )
    ])
    error_message = "When 'os' is set to 'custom', a valid 'ami_id' must be explicitly provided."
  }
}

variable "default_iam_instance_profile" {
  description = "Fallback IAM instance profile to attach if not specified per instance."
  type        = string
  default     = null
}

variable "default_security_group_ids" {
  description = "Fallback list of security group IDs to attach if not specified per instance."
  type        = list(string)
  default     = []
}

variable "common_tags" {
  description = "Common tags applied to all EC2 instances and associated EBS volumes."
  type        = map(string)
  default     = {}
}
