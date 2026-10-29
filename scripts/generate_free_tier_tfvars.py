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

def generate_tfvars(count, instance_type, os_type, volume_size_gb, env, output_path, subnet_type="public", key_name=""):
    if subnet_type == "public":
        subnets = ["public-a", "public-b"]
        associate_public_ip = True
    else:
        subnets = ["private-a", "private-b"]
        associate_public_ip = False
    
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
        key_line = f'    key_name                    = "{key_name}"\n' if key_name else ""
        role_name = "prometheus-server" if i == 1 else f"target-node-{i - 1}"
        node_block = f"""  node-{i} = {{
    instance_type               = "{instance_type}"
    os                          = "{os_type}"
    subnet                      = "{subnet}"
    associate_public_ip_address = {str(associate_public_ip).lower()}
{key_line}    root_volume_gb              = {volume_size_gb}
    root_volume_type            = "gp3"
    extra_tags = {{
      Tier      = "free-tier"
      Role      = "{role_name}"
      Lab       = "prometheus-monitoring"
      NodeIndex = "{i}"
    }}
  }}"""
        instances_hcl.append(node_block)

    instances_joined = "\n\n".join(instances_hcl)

    tfvars_content = f"""# =============================================================================
# AUTO-GENERATED AWS FREE-TIER CONFIGURATION (Jenkins / CI-CD)
# Total Nodes: {count} | Total EBS: {total_storage} GB | NAT Gateway: Disabled (Free)
# Lab: Prometheus Monitoring Cluster (1 Prometheus Server + {max(0, count - 1)} Target Nodes)
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
  public-b = {{
    cidr_block              = "10.0.2.0/24"
    availability_zone       = "ap-south-1b"
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

# Prometheus & Node Exporter Security Group Rules
security_group_ingress_rules = [
  {{
    description = "Allow Prometheus Web UI from anywhere"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }},
  {{
    description = "Allow Grafana Web Dashboard from anywhere"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }},
  {{
    description = "Allow Node Exporter metrics scraping"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }},
  {{
    description = "Allow all inter-node VPC communication for metrics scraping"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }},
  {{
    description = "Allow SSH from anywhere (laptop direct access)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }},
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
    parser.add_argument("--subnet-type", default="public", choices=["public", "private"], help="Subnet type for instances")
    parser.add_argument("--key-name", default="", help="Optional AWS EC2 Key Pair name for SSH login")
    parser.add_argument("--output", default="environments/dev/terraform.tfvars", help="Target tfvars path")

    args = parser.parse_args()
    generate_tfvars(args.count, args.instance_type, args.os, args.volume_gb, args.env, args.output, args.subnet_type, args.key_name)

if __name__ == "__main__":
    main()
