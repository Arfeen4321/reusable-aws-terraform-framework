# -----------------------------------------------------------------------------
# EC2 INSTANCE RESOURCE DEFINITIONS
# -----------------------------------------------------------------------------

resource "aws_instance" "this" {
  for_each = var.instances

  ami = (
    each.value.ami_id != null ? each.value.ami_id :
    local.ami_map[coalesce(each.value.os, "ubuntu")]
  )

  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  associate_public_ip_address = coalesce(each.value.associate_public_ip_address, false)
  monitoring                  = coalesce(each.value.enable_monitoring, false)
  disable_api_termination     = coalesce(each.value.disable_api_termination, false)
  key_name                    = each.value.key_name

  iam_instance_profile = (
    each.value.iam_instance_profile != null ? each.value.iam_instance_profile :
    var.default_iam_instance_profile
  )

  vpc_security_group_ids = (
    length(coalesce(each.value.security_group_ids, [])) > 0 ? each.value.security_group_ids :
    var.default_security_group_ids
  )

  user_data        = each.value.user_data
  user_data_base64 = each.value.user_data_base64

  # Enforce IMDSv2 (Defends against SSRF vulnerabilities)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 strictly enforced
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Configurable Root EBS Block Device
  root_block_device {
    volume_size           = coalesce(each.value.root_volume_size, 20)
    volume_type           = coalesce(each.value.root_volume_type, "gp3")
    encrypted             = coalesce(each.value.root_volume_encrypted, true)
    kms_key_id            = each.value.root_kms_key_id
    delete_on_termination = true

    tags = merge(
      var.common_tags,
      coalesce(each.value.extra_tags, {}),
      {
        Name        = "${var.environment}-${each.key}-root-volume"
        Environment = var.environment
        InstanceKey = each.key
      }
    )
  }

  tags = merge(
    var.common_tags,
    coalesce(each.value.extra_tags, {}),
    {
      Name        = "${var.environment}-${each.key}"
      Environment = var.environment
      InstanceKey = each.key
      OS          = coalesce(each.value.os, "ubuntu")
    }
  )

  lifecycle {
    ignore_changes = [
      ami, # Prevent involuntary replacement when newer AMI builds are published
    ]
  }
}

# -----------------------------------------------------------------------------
# ADDITIONAL EBS VOLUMES (OPTIONAL PER INSTANCE)
# -----------------------------------------------------------------------------
locals {
  flattened_ebs_volumes = merge([
    for inst_key, inst_val in var.instances : {
      for vol_key, vol_val in coalesce(inst_val.additional_ebs_volumes, {}) :
      "${inst_key}.${vol_key}" => {
        instance_key = inst_key
        vol_key      = vol_key
        device_name  = vol_val.device_name
        size_gb      = vol_val.size_gb
        type         = coalesce(vol_val.type, "gp3")
        encrypted    = coalesce(vol_val.encrypted, true)
        kms_key_id   = vol_val.kms_key_id
      }
    }
  ]...)
}

resource "aws_ebs_volume" "additional" {
  for_each = local.flattened_ebs_volumes

  availability_zone = aws_instance.this[each.value.instance_key].availability_zone
  size              = each.value.size_gb
  type              = each.value.type
  encrypted         = each.value.encrypted
  kms_key_id        = each.value.kms_key_id

  tags = merge(
    var.common_tags,
    {
      Name        = "${var.environment}-${each.value.instance_key}-${each.value.vol_key}"
      Environment = var.environment
      AttachedTo  = each.value.instance_key
      Device      = each.value.device_name
    }
  )
}

resource "aws_volume_attachment" "additional" {
  for_each = local.flattened_ebs_volumes

  device_name = each.value.device_name
  volume_id   = aws_ebs_volume.additional[each.key].id
  instance_id = aws_instance.this[each.value.instance_key].id
}
