locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = merge({
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }, var.additional_tags)

  create_s3_bucket   = var.create_s3_bucket
  create_ec2         = var.create_ec2
  create_rds         = var.create_rds
  create_iam         = var.create_iam || local.create_ec2
  create_nat_gateway = var.create_nat_gateway || local.create_ec2
  # NLB zakomentarisan — koristimo ALB
  # create_nlb           = var.create_nlb && local.create_ec2
  create_nlb           = false
  create_alb           = var.create_alb && local.create_ec2
  create_vpc_endpoints = var.create_vpc_endpoints

  # Kad je ALB ukljucen, kreiramo 2 EC2 instance u razlicitim AZ-ovima za HA
  ec2_instance_count = local.create_alb ? 2 : (local.create_ec2 ? 1 : 0)

  create_vpc              = var.create_vpc || local.create_ec2 || local.create_rds || local.create_nlb || local.create_alb || local.create_vpc_endpoints
  create_public_subnet    = local.create_vpc && (local.create_nat_gateway || local.create_nlb || local.create_alb)
  create_public_subnet_b  = local.create_vpc && (local.create_nlb || local.create_alb)
  create_private_subnet   = local.create_vpc && (local.create_ec2 || local.create_rds || local.create_vpc_endpoints)
  create_private_subnet_b = local.create_vpc && (local.create_rds || local.create_alb)
}
