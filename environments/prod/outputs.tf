output "vpc_id" {
  description = "VPC ID."
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "Map of public subnets."
  value       = module.vpc.public_subnet_ids
}

output "private_subnets" {
  description = "Map of private subnets."
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_public_ips" {
  description = "High Availability NAT Gateway Elastic IP addresses across AZs."
  value       = module.vpc.nat_gateway_public_ips
}

output "security_group_id" {
  description = "Security Group ID assigned to EC2 instances."
  value       = module.security_groups.security_group_id
}

output "iam_role_arn" {
  description = "IAM Role ARN attached to instances."
  value       = module.iam.role_arn
}

output "backup_bucket_name" {
  description = "Encrypted S3 backup bucket name."
  value       = module.storage.backup_bucket_name
}

output "ec2_instances" {
  description = "Detailed map of all provisioned EC2 instances."
  value       = module.ec2.instances
}

output "instance_summary" {
  description = "Concise summary table of provisioned instances."
  value = {
    for k, v in module.ec2.instances : k => {
      id                = v.id
      instance_type     = v.instance_type
      private_ip        = v.private_ip
      public_ip         = v.public_ip != "" ? v.public_ip : "none (private)"
      availability_zone = v.availability_zone
      root_volume_id    = v.root_volume_id
    }
  }
}
