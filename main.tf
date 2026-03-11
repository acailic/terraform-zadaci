# =============================================================================
# Infra – Single-root Terraform configuration
#
# Manages IAM (iam.tf) and application resources (VPC, subnet, EC2, S3)
# in a single state. Uses the terraform profile directly.
# =============================================================================

# ----- Test S3 bucket --------------------------------------------------------

resource "aws_s3_bucket" "test" {
  bucket        = "${local.name_prefix}-test-bucket"
  force_destroy = true

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

# ----- VPC + Subnet ---------------------------------------------------------

resource "aws_vpc" "test" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true ## dodaje public IP na instance u ovom subnetu

  tags = { Name = "${local.name_prefix}-public-subnet" }
}
## 

# ----- Internet Gateway + Public Route Table --------------------------------

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.test.id

  tags = { Name = "${local.name_prefix}-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.test.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ----- Security Group -------------------------------------------------------

resource "aws_security_group" "web" {
  vpc_id      = aws_vpc.test.id
  description = "Allow HTTP inbound"

  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_egress_cidr_blocks
  }

  tags = { Name = "${local.name_prefix}-web-sg" }
}

# ----- EC2 instance ---------------------------------------------------------

resource "aws_instance" "test" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html
  EOF

  tags = { Name = "${local.name_prefix}-ec2" }
}
