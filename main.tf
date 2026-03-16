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

# ----- Private Subnet --------------------------------------------------------

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-private-subnet" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.test.id

  # No routes — no internet access. VPC endpoints provide AWS service access.

  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
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

# ----- VPC Endpoint Security Group -------------------------------------------

resource "aws_security_group" "vpce" {
  vpc_id      = aws_vpc.test.id
  description = "Allow HTTPS from VPC CIDR for SSM VPC endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-vpce-sg" }
}

# ----- VPC Endpoints for SSM (PrivateLink) ------------------------------------

resource "aws_vpc_endpoint" "ssm" {
  for_each = toset([
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages",
  ])

  vpc_id              = aws_vpc.test.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce.id]

  tags = {
    Name = "${local.name_prefix}-${split(".", each.value)[length(split(".", each.value)) - 1]}-vpce"
  }
}

# ----- TLS Private Key + Secrets Manager -------------------------------------
# Generise SSH key par u Terraformu. Privatni kljuc se cuva u AWS Secrets Manager.
# Rotacija kljuceva je bitna — moze se automatizovati sa Lambda funkcijom.

resource "tls_private_key" "main" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "main" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = { Name = "${local.name_prefix}-key" }
}

resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret" "ssh_private_key" {
  name                    = "${local.name_prefix}-ssh-private-key-${random_id.secret_suffix.hex}"
  description             = "SSH private key for EC2 instance access (managed by Terraform)"
  recovery_window_in_days = 0 # Dev environment — allow immediate deletion on destroy

  tags = { Name = "${local.name_prefix}-ssh-private-key" }
}

resource "aws_secretsmanager_secret_version" "ssh_private_key" {
  secret_id     = aws_secretsmanager_secret.ssh_private_key.id
  secret_string = tls_private_key.main.private_key_openssh
}

# ----- EC2 SSM Instance Profile ---------------------------------------------

resource "aws_iam_role" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.name_prefix}-ec2-ssm-role" }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm.name

  tags = { Name = "${local.name_prefix}-ec2-ssm-profile" }
}

# ----- EC2 instance ---------------------------------------------------------

resource "aws_instance" "test" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  # NOTE: user_data yum komande zahtevaju internet. U private subnetu bez NAT-a
  # nece raditi. SSM Agent je pre-instaliran na Amazon Linux 2023, tako da SSM
  # i dalje radi. Dodati NAT gateway ili S3 gateway endpoint ako treba yum.
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
