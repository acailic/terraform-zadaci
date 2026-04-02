# =============================================================================
# Infra – Single-root Terraform configuration
#
# Resources are split across files by domain:
#   main.tf           – S3 bucket
#   vpc.tf            – VPC, subnets, IGW, NAT gateway, route tables
#   ec2.tf            – EC2 instance, SSH key, security group, user_data
#   nlb.tf            – NLB (+ commented ALB), target groups, listeners
#   rds.tf            – RDS MySQL, RDS SG, DB subnet group, credentials secret
#   vpc-endpoints.tf  – SSM PrivateLink endpoints, S3 Gateway endpoint
#   iam.tf            – IAM roles, policies, instance profile
#   variables.tf      – Input variables
#   outputs.tf        – Output values
#   locals.tf         – Local values
#   versions.tf       – Provider config with assume_role
#   backend.tf        – S3 remote state backend
#
# Uses the terraform profile with assume_role to TerraformAdminRole.
# =============================================================================

# ----- Test S3 bucket --------------------------------------------------------

resource "aws_s3_bucket" "test" {
  count = local.create_s3_bucket ? 1 : 0

  bucket        = "${local.name_prefix}-test-bucket"
  force_destroy = true

  tags = { Name = "${local.name_prefix}-test-bucket" }
}

resource "aws_s3_bucket_versioning" "test" {
  count = local.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.test[0].id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test" {
  count = local.create_s3_bucket ? 1 : 0

  bucket = aws_s3_bucket.test[0].id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  count = local.create_s3_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.test[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
