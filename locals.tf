locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }, var.additional_tags)

  create_s3_bucket     = var.create_s3_bucket
  create_ec2           = var.create_ec2
  create_rds           = var.create_rds
  create_iam           = var.create_iam || local.create_ec2
  create_nat_gateway   = var.create_nat_gateway || local.create_ec2
  create_nlb           = var.create_nlb && local.create_ec2
  create_vpc_endpoints = var.create_vpc_endpoints

  create_vpc              = var.create_vpc || local.create_ec2 || local.create_rds || local.create_nlb || local.create_vpc_endpoints
  create_public_subnet    = local.create_vpc && (local.create_nat_gateway || local.create_nlb)
  create_public_subnet_b  = local.create_vpc && local.create_nlb
  create_private_subnet   = local.create_vpc && (local.create_ec2 || local.create_rds || local.create_vpc_endpoints)
  create_private_subnet_b = local.create_vpc && local.create_rds
}
