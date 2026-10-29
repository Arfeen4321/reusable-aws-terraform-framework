output "instances" {
  description = "Detailed map of provisioned EC2 instances keyed by their stable logical names."
  value = {
    for k, v in aws_instance.this : k => {
      id                  = v.id
      arn                 = v.arn
      instance_type       = v.instance_type
      private_ip          = v.private_ip
      public_ip           = v.public_ip
      subnet_id           = v.subnet_id
      availability_zone   = v.availability_zone
      ami                 = v.ami
      key_name            = v.key_name
      root_volume_id      = v.root_block_device[0].volume_id
      security_group_ids  = v.vpc_security_group_ids
      iam_instance_profile = v.iam_instance_profile
    }
  }
}

output "instance_ids" {
  description = "Map of instance logical keys to AWS EC2 instance IDs."
  value       = { for k, v in aws_instance.this : k => v.id }
}

output "instance_private_ips" {
  description = "Map of instance logical keys to their private IP addresses."
  value       = { for k, v in aws_instance.this : k => v.private_ip }
}

output "instance_public_ips" {
  description = "Map of instance logical keys to their assigned public IP addresses (if public)."
  value       = { for k, v in aws_instance.this : k => v.public_ip }
}

output "instance_types" {
  description = "Map of instance logical keys to their provisioned instance types."
  value       = { for k, v in aws_instance.this : k => v.instance_type }
}

output "additional_ebs_volume_ids" {
  description = "Map of additional EBS volume keys to volume IDs."
  value       = { for k, v in aws_ebs_volume.additional : k => v.id }
}
