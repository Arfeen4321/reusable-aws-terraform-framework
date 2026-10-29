module "vpc" {
  source = "../../modules/vpc"

  environment          = var.environment
  vpc_name             = "vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  enable_s3_endpoint   = var.enable_s3_endpoint
  enable_ssm_endpoints = var.enable_ssm_endpoints
  tags                 = var.tags
}

module "iam" {
  source = "../../modules/iam"

  environment             = var.environment
  role_name_prefix        = "node"
  enable_ssm              = true
  enable_cloudwatch_agent = true
  tags                    = var.tags
}

module "security_groups" {
  source = "../../modules/security-groups"

  vpc_id              = module.vpc.vpc_id
  environment         = var.environment
  security_group_name = "node-sg"
  description         = "Production security group with least privilege access"
  ingress_rules       = var.security_group_ingress_rules
  egress_rules        = var.security_group_egress_rules
  tags                = var.tags
}

module "storage" {
  source = "../../modules/storage"

  environment               = var.environment
  project_name              = var.project_name
  enable_backup_bucket      = var.enable_backup_bucket
  lifecycle_expiration_days = 180
  tags                      = var.tags
}

locals {
  all_subnets = merge(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)

  resolved_instances = {
    for k, v in var.instances : k => {
      instance_type               = v.instance_type
      os                          = v.os
      ami_id                      = v.ami_id
      subnet_id                   = local.all_subnets[v.subnet]
      associate_public_ip_address = v.associate_public_ip_address
      root_volume_size            = v.root_volume_gb
      root_volume_type            = v.root_volume_type
      root_volume_encrypted       = v.root_volume_encrypted
      enable_monitoring           = v.enable_monitoring
      disable_api_termination     = v.disable_api_termination
      key_name                    = v.key_name
      user_data                   = v.user_data
      extra_tags                  = v.extra_tags
      additional_ebs_volumes      = v.additional_ebs_volumes
    }
  }
}

module "ec2" {
  source = "../../modules/ec2"

  environment                  = var.environment
  instances                    = local.resolved_instances
  default_iam_instance_profile = module.iam.instance_profile_name
  default_security_group_ids   = [module.security_groups.security_group_id]
  common_tags                  = var.tags
}
