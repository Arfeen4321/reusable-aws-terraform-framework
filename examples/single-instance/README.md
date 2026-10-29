# Example: Single Instance Deployment

This example demonstrates deploying a single cost-effective `t3.micro` EC2 node in a public subnet with an assigned public IP address.

## Use Case
- Minimal development sandbox
- Lightweight bastion or jump host
- Fast smoke testing of VPC and IAM configurations

## How to Test
1. Copy `terraform.tfvars` from this directory into `environments/dev/`:
   ```bash
   cp examples/single-instance/terraform.tfvars environments/dev/terraform.tfvars
   ```
2. Navigate to `environments/dev`:
   ```bash
   cd environments/dev
   terraform plan
   ```
3. Verify that exactly 1 EC2 instance (`bastion-node`) will be created without modifying any underlying Terraform modules.
