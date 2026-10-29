#!/usr/bin/env python3
"""
Generate Free-Tier AWS terraform.tfvars dynamically based on instance count.
Enforces AWS Free-Tier best practices:
- Instance types: t2.micro or t3.micro
- Total EBS storage across instances <= 30 GB
- NAT Gateway: Disabled (0 cost)
- S3 Gateway Endpoint: Enabled (Free)
"""

import argparse
import os
import sys

def generate_tfvars(count, instance_type, os_type, volume_size_gb, env, output_path):
    subnets = ["private-a", "private-b"]
    
    # Calculate total storage
    total_storage = count * volume_size_gb
    if total_storage > 30:
        print(f"[WARNING] Total storage ({total_storage} GB) exceeds AWS Free Tier limit (30 GB/month).", file=sys.stderr)
        print("          AWS may charge standard EBS rates ($0.08/GB-month) for storage exceeding 30 GB.", file=sys.stderr)
    else:
        print(f"[INFO] Total storage is {total_storage} GB (Within 30 GB AWS Free Tier limit).")

    instances_hcl = []
    for i in range(1, count + 1):
        subnet = subnets[(i - 1) % len(subnets)]
        node_block = f"""  node-{i} = {{
    instance_type  = "{instance_type}"
    os             = "{os_type}"
    subnet         = "{subnet}"
    root_volume_gb = {volume_size_gb}
    root_volume_type = "gp3"
    extra_tags = {{
      Tier      = "free-tier"
      NodeIndex = "{i}"
    }}
  }}"""
        instances_hcl.append(node_block)

    instances_joined = "\n\n".join(instances_hcl)

    tfvars_content = f"""# =============================================================================
# AUTO-GENERATED AWS FREE-TIER CONFIGURATION (Jenkins / CI-CD)
# Total Nodes: {count} | Total EBS: {total_storage} GB | NAT Gateway: Disabled (Free)
# =============================================================================

aws_region   = "ap-south-1"
environment  = "{env}"
project_name = "iac-framework"

vpc_cidr = "10.0.0.0/16"

public_subnets = {{
  public-a = {{
    cidr_block              = "10.0.1.0/24"
    availability_zone       = "ap-south-1a"
    map_public_ip_on_launch = true
  }}
}}

private_subnets = {{
  private-a = {{
    cidr_block        = "10.0.10.0/24"
    availability_zone = "ap-south-1a"
  }}
  private-b = {{
    cidr_block        = "10.0.20.0/24"
    availability_zone = "ap-south-1b"
  }}
}}

# Free-Tier Cost Optimization: NAT Gateway is DISABLED (saves ~$32.85/month)
enable_nat_gateway   = false
single_nat_gateway   = true
enable_s3_endpoint   = true
enable_ssm_endpoints = false
enable_backup_bucket = false

# Least-privilege internal VPC traffic
security_group_ingress_rules = [
  {{
    description = "Allow internal HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }},
  {{
    description = "Allow internal HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }}
]

# Dynamically generated instance definitions
instances = {{
{instances_joined}
}}

tags = {{
  Environment = "{env}"
  ManagedBy   = "Jenkins-CI-CD"
  Tier        = "AWS-Free-Tier"
}}
"""

    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(tfvars_content)

    print(f"[SUCCESS] Successfully generated Free-Tier tfvars at: {output_path}")

def main():
    parser = argparse.ArgumentParser(description="Generate Free Tier tfvars for Terraform")
    parser.add_argument("--count", type=int, default=1, help="Number of instances to create")
    parser.add_argument("--instance-type", default="t3.micro", choices=["t3.micro", "t2.micro"], help="Instance type")
    parser.add_argument("--os", default="ubuntu", choices=["ubuntu", "amazon-linux"], help="OS flavor")
    parser.add_argument("--volume-gb", type=int, default=10, help="EBS size in GB per instance")
    parser.add_argument("--env", default="dev", help="Environment (e.g. dev)")
    parser.add_argument("--output", default="environments/dev/terraform.tfvars", help="Target tfvars path")

    args = parser.parse_args()
    generate_tfvars(args.count, args.instance_type, args.os, args.volume_gb, args.env, args.output)

if __name__ == "__main__":
    main()
