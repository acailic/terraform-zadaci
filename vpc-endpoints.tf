# =============================================================================
# VPC Endpoints – SSM PrivateLink + S3 Gateway
# =============================================================================

# ----- VPC Endpoint Security Group -------------------------------------------

resource "aws_security_group" "vpce" {
  count = local.create_vpc_endpoints ? 1 : 0

  vpc_id      = aws_vpc.test[0].id
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
  for_each = local.create_vpc_endpoints ? toset([
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages",
  ]) : toset([])

  vpc_id              = aws_vpc.test[0].id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [aws_subnet.private[0].id]
  security_group_ids  = [aws_security_group.vpce[0].id]

  tags = {
    Name = "${local.name_prefix}-${split(".", each.value)[length(split(".", each.value)) - 1]}-vpce"
  }
}

# ----- S3 Gateway Endpoint (free) ---------------------------------------------
# da ne ide preko NAT, vec direktno preko AWS backbone-a. Ne koristi se security group jer je Gateway endpoint.
resource "aws_vpc_endpoint" "s3" {
  count = local.create_vpc_endpoints ? 1 : 0

  vpc_id            = aws_vpc.test[0].id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private[0].id]

  tags = { Name = "${local.name_prefix}-s3-vpce" }
}
