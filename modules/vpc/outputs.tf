output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = aws_vpc.this.arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  description = "Map of public subnet keys to subnet IDs."
  value       = { for k, v in aws_subnet.public : k => v.id }
}

output "private_subnet_ids" {
  description = "Map of private subnet keys to subnet IDs."
  value       = { for k, v in aws_subnet.private : k => v.id }
}

output "public_subnet_arns" {
  description = "Map of public subnet keys to subnet ARNs."
  value       = { for k, v in aws_subnet.public : k => v.arn }
}

output "private_subnet_arns" {
  description = "Map of private subnet keys to subnet ARNs."
  value       = { for k, v in aws_subnet.private : k => v.arn }
}

output "internet_gateway_id" {
  description = "The ID of the Internet Gateway."
  value       = length(aws_internet_gateway.this) > 0 ? aws_internet_gateway.this[0].id : null
}

output "nat_gateway_ids" {
  description = "Map of NAT Gateway IDs."
  value       = { for k, v in aws_nat_gateway.this : k => v.id }
}

output "nat_gateway_public_ips" {
  description = "Map of public IP addresses assigned to the NAT Gateways."
  value       = { for k, v in aws_eip.nat : k => v.public_ip }
}

output "s3_endpoint_id" {
  description = "The ID of the S3 Gateway VPC Endpoint."
  value       = length(aws_vpc_endpoint.s3) > 0 ? aws_vpc_endpoint.s3[0].id : null
}
