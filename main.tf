# =============================================================================
# ZADATAK 1 – Test resources
#
# These prove that assume-role works: terraform-user has NO direct EC2/VPC/S3
# permissions — everything below is created via TerraformAdminRole.
#
# IMPORTANT: depends_on ensures the IAM role + policies are destroyed AFTER
# these resources; otherwise Terraform loses assume-role access mid-destroy.
# =============================================================================

# ----- Test S3 bucket (resource, NOT the state backend) ----------------------

resource "aws_s3_bucket" "test" {
  bucket        = "${local.name_prefix}-test-bucket"
  force_destroy = true # easy cleanup for learning
  depends_on    = [aws_iam_role_policy_attachment.admin]

  tags = { Name = "${local.name_prefix}-test-bucket" }
}

resource "aws_s3_bucket_versioning" "test" {
  bucket = aws_s3_bucket.test.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "test" {
  bucket = aws_s3_bucket.test.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket                  = aws_s3_bucket.test.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ----- Test VPC + Subnet ----------------------------------------------------

resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  depends_on           = [aws_iam_role_policy_attachment.admin]

  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "test" {
  vpc_id            = aws_vpc.test.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = { Name = "${local.name_prefix}-subnet" }
}

# ----- Test EC2 instance -----------------------------------------------------

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "test" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.test.id

  tags = { Name = "${local.name_prefix}-ec2" }
}
