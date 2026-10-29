# Example: Mixed Instance Types and Heterogeneous Configurations

This example showcases the input-driven capabilities of the framework by provisioning:
- 2x `t3.small` instances (Ubuntu 22.04 and Debian 12)
- 3x `t3.medium` instances (Amazon Linux 2023 and Red Hat Enterprise Linux 9)
- Heterogeneous disk sizes (20 GB, 25 GB, 40 GB, and 80 GB)
- Mixed subnet placement (`private-a` and `private-b`)
- Secondary EBS volume attached to `db-medium-3` on `/dev/xvdf`

## How to Test
1. Copy `terraform.tfvars` from this directory into `environments/dev/`:
   ```bash
   cp examples/mixed-instance-types/terraform.tfvars environments/dev/terraform.tfvars
   ```
2. Navigate to `environments/dev`:
   ```bash
   cd environments/dev
   terraform plan
   ```
3. Observe the Terraform execution plan:
   - 5 EC2 instances created in parallel.
   - Each instance resolves to its respective AMI, subnet, and EBS volume configuration based strictly on input variables.
