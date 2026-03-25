# =============================================================================
# VPC – subnets, internet gateway, NAT gateway, route tables
# =============================================================================

# ----- VPC + Subnet ---------------------------------------------------------

resource "aws_vpc" "test" {
  count = local.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name_prefix}-vpc" }
}

resource "aws_subnet" "public" {
  count = local.create_public_subnet ? 1 : 0

  vpc_id                  = aws_vpc.test[0].id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false ## dodaje public IP na instance u ovom subnetu
  ### probati izlaz sa masine ß
  tags = { Name = "${local.name_prefix}-public-subnet" }
}


# ----- Internet Gateway + Public Route Table --------------------------------

resource "aws_internet_gateway" "main" {
  count = local.create_public_subnet ? 1 : 0

  vpc_id = aws_vpc.test[0].id

  tags = { Name = "${local.name_prefix}-igw" }
}

resource "aws_route_table" "public" {
  count = local.create_public_subnet ? 1 : 0

  vpc_id = aws_vpc.test[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main[0].id
  }

  tags = { Name = "${local.name_prefix}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count = local.create_public_subnet ? 1 : 0

  subnet_id      = aws_subnet.public[0].id
  route_table_id = aws_route_table.public[0].id
}

# ----- Private Subnet --------------------------------------------------------

resource "aws_subnet" "private" {
  count = local.create_private_subnet ? 1 : 0

  vpc_id                  = aws_vpc.test[0].id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-private-subnet" }
}

resource "aws_route_table" "private" {
  count = local.create_private_subnet ? 1 : 0

  vpc_id = aws_vpc.test[0].id

  dynamic "route" {
    for_each = local.create_nat_gateway ? [1] : []

    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[0].id
    }
  }

  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  count = local.create_private_subnet ? 1 : 0

  subnet_id      = aws_subnet.private[0].id
  route_table_id = aws_route_table.private[0].id
}

# ----- NAT Gateway -----------------------------------------------------------

resource "aws_eip" "nat" {
  count = local.create_nat_gateway ? 1 : 0

  domain = "vpc"

  tags = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  count = local.create_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id

  tags = { Name = "${local.name_prefix}-nat-gw" }

  depends_on = [aws_internet_gateway.main[0]]
}

# ----- Drugi public subnet (potreban i za NLB — 2 AZ-a) ----------------------
# NLB ne zahteva 2 AZ-a kao ALB, ali je best practice za high availability.

resource "aws_subnet" "public_b" {
  count = local.create_public_subnet_b ? 1 : 0

  vpc_id                  = aws_vpc.test[0].id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-public-subnet-b" }
}

resource "aws_route_table_association" "public_b" {
  count = local.create_public_subnet_b ? 1 : 0

  subnet_id      = aws_subnet.public_b[0].id
  route_table_id = aws_route_table.public[0].id
}

# ----- Drugi private subnet (RDS zahteva 2 AZ-e za subnet group) -------------

resource "aws_subnet" "private_b" {
  count = local.create_private_subnet_b ? 1 : 0

  vpc_id                  = aws_vpc.test[0].id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-private-subnet-b" }
}

resource "aws_route_table_association" "private_b" {
  count = local.create_private_subnet_b ? 1 : 0

  subnet_id      = aws_subnet.private_b[0].id
  route_table_id = aws_route_table.private[0].id
}
