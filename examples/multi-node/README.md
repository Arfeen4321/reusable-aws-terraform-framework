# Example: Multi-Node Scaled Cluster (5x t2.micro)

This example provisions 5 identical `t2.micro` worker nodes across multiple private subnets (`private-a` and `private-b`).

## Key Advantages of Stable `for_each` Keys
Notice that instances are keyed by unique, stable string identifiers (`worker-1` through `worker-5`) rather than numeric list indices (`count.index`):
- **Removing a node**: Removing `worker-3` from `instances` will instruct Terraform to destroy **only** `worker-3`. Nodes `worker-1`, `worker-2`, `worker-4`, and `worker-5` remain completely untouched.
- **Contrast with `count`**: With `count`, removing the 3rd element causes every subsequent instance (`worker-4` and `worker-5`) to shift indices, leading to catastrophic, unintended instance recreation in production!

## How to Test
1. Copy `terraform.tfvars` from this directory into `environments/dev/`:
   ```bash
   cp examples/multi-node/terraform.tfvars environments/dev/terraform.tfvars
   ```
2. Navigate to `environments/dev`:
   ```bash
   cd environments/dev
   terraform plan
   ```
3. To alter the instance type to `t3.medium`, simply update `instance_type = "t3.medium"` for the desired nodes and re-run `terraform plan`.
