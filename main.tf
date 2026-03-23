# =============================================================================
# Infra – Single-root Terraform configuration
#
# Application resources (VPC, subnet, EC2, S3). IAM lives in iam.tf.
# Uses the terraform profile with assume_role to TerraformAdminRole.
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
  map_public_ip_on_launch = false ## dodaje public IP na instance u ovom subnetu
### probati izlaz sa masine ß
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

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = { Name = "${local.name_prefix}-private-rt" }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# ----- NAT Gateway -----------------------------------------------------------

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = { Name = "${local.name_prefix}-nat-eip" }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = { Name = "${local.name_prefix}-nat-gw" }

  depends_on = [aws_internet_gateway.main]
}

# ----- Security Group -------------------------------------------------------

resource "aws_security_group" "web" {
  vpc_id      = aws_vpc.test.id
  description = "Allow SSH inbound for NLB (NLB has no SG - passes client IP directly)"

  # NLB radi na Layer 4 (TCP) i NEMA security group.
  # NLB propušta originalni client source IP do EC2.
  # Zato EC2 SG mora da dozvoli SSH od CIDR blokova, ne od SG-a.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH via NLB (client IP passthrough)"
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

# ----- S3 Gateway Endpoint (free) ---------------------------------------------
# da ne ide preko NAT, vec direktno preko AWS backbone-a. Ne koristi se security group jer je Gateway endpoint.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.test.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = { Name = "${local.name_prefix}-s3-vpce" }
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

# ----- EC2 instance ---------------------------------------------------------

resource "aws_instance" "test" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = aws_key_pair.main.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm.name

  # user_data runs on instance launch. The private subnet reaches the internet
  # via the NAT gateway in the public subnet.
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    yum update -y
    yum install -y httpd mysql
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello from $(hostname -f)</h1>" > /var/www/html/index.html

  EOF

  tags = { Name = "${local.name_prefix}-ec2" }
}
### update mariadb installation da radi. aws cli da procita seccret. ili coonection string i da se sacuva na files.
#### kod bash cat ili echo ili > da se insertuje na file.
##### update user data with javascript, to load secrets from secrets, da se sacuva conneciton string 
###### prilikom kreirajanja instance napraviti skripty da ucita secrete pomocu aws cli i stavi ga kao ENV varijably
###### da u kodu ucita konekciju za bazu .


# =============================================================================
# ALB – zakomentarisan (option b: NLB umesto ALB-a)
# =============================================================================

# ----- Drugi public subnet (potreban i za NLB — 2 AZ-a) ----------------------
# NLB ne zahteva 2 AZ-a kao ALB, ali je best practice za high availability.

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = { Name = "${local.name_prefix}-public-subnet-b" }
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ----- ALB Security Group (zakomentarisan — NLB nema SG) ---------------------
# resource "aws_security_group" "alb" {
#   vpc_id      = aws_vpc.test.id
#   description = "Allow HTTP inbound to ALB from the internet"
#
#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#     description = "HTTP from internet"
#   }
#
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#
#   tags = { Name = "${local.name_prefix}-alb-sg" }
# }

# ----- ALB (zakomentarisan) ---------------------------------------------------
# resource "aws_lb" "main" {
#   name               = "${local.name_prefix}-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb.id]
#   subnets            = [aws_subnet.public.id, aws_subnet.public_b.id]
#
#   tags = { Name = "${local.name_prefix}-alb" }
# }

# ----- ALB Target Group (zakomentarisan) --------------------------------------
# resource "aws_lb_target_group" "web" {
#   name     = "${local.name_prefix}-tg"
#   port     = 80
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.test.id
#
#   health_check {
#     path                = "/index.html"
#     protocol            = "HTTP"
#     healthy_threshold   = 2
#     unhealthy_threshold = 3
#     timeout             = 5
#     interval            = 30
#     matcher             = "200"
#   }
#
#   tags = { Name = "${local.name_prefix}-tg" }
# }

# ----- ALB Target Group Attachment (zakomentarisan) ---------------------------
# resource "aws_lb_target_group_attachment" "web" {
#   target_group_arn = aws_lb_target_group.web.arn
#   target_id        = aws_instance.test.id
#   port             = 80
# }

# ----- ALB HTTP Listener (zakomentarisan) -------------------------------------
# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.main.arn
#   port              = 80
#   protocol          = "HTTP"
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.web.arn
#   }
# }

# =============================================================================
# NLB – Network Load Balancer (option b)
#
# NLB radi na Layer 4 (TCP/UDP) — prosleđuje TCP konekcije bez inspekcije.
# Razlike u odnosu na ALB:
#   - NLB NEMA security group — client IP se propušta direktno do EC2
#   - NLB podržava statičke IP adrese (Elastic IP po AZ-u)
#   - NLB ima mnogo manji latency (milioni req/s)
#   - NLB ne može da rutira po URL path-u (to radi ALB na Layer 7)
#   - Health check: TCP konekcija na port 22 (ne HTTP GET)
# =============================================================================

resource "aws_lb" "nlb" {
  name               = "${local.name_prefix}-nlb"
  internal           = false # internet-facing
  load_balancer_type = "network"
  # NLB nema security_groups parametar!
  subnets = [aws_subnet.public.id, aws_subnet.public_b.id]

  tags = { Name = "${local.name_prefix}-nlb" }
}

# ----- NLB Target Group (TCP port 22) ----------------------------------------
# Target Group za NLB koristi protocol = "TCP" (ne HTTP).
# Health check je TCP — samo proverava da li može da otvori konekciju na port 22.

resource "aws_lb_target_group" "ssh" {
  name     = "${local.name_prefix}-ssh-tg"
  port     = 22
  protocol = "TCP"
  vpc_id   = aws_vpc.test.id

  health_check {
    protocol            = "TCP"       # TCP check — samo proveri da li je port otvoren
    port                = 22
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10          # NLB podržava 10s interval (ALB min 30s)
  }

  tags = { Name = "${local.name_prefix}-ssh-tg" }
}

# ----- NLB Target Group Attachment --------------------------------------------

resource "aws_lb_target_group_attachment" "ssh" {
  target_group_arn = aws_lb_target_group.ssh.arn
  target_id        = aws_instance.test.id
  port             = 22
}

# ----- NLB TCP Listener (port 22) --------------------------------------------
# Sluša na NLB-u na portu 22 i prosleđuje TCP konekcije na Target Group.

resource "aws_lb_listener" "ssh" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ssh.arn
  }
}

# =============================================================================
# RDS MySQL — z7
#
# Free Tier: db.t3.micro, 20 GB, 750 sati/mesec (12 meseci).
# Baza je u private subnet-u, dostupna samo od EC2 instance (SG chaining).
# Kredencijali se cuvaju u Secrets Manager-u kao JSON.
# =============================================================================

# ----- Drugi private subnet (RDS zahteva 2 AZ-e za subnet group) -------------

resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.test.id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = { Name = "${local.name_prefix}-private-subnet-b" }
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

# ----- RDS Security Group ----------------------------------------------------
# Dozvoljava MySQL (3306) samo od EC2 security grupe — security group chaining.

resource "aws_security_group" "rds" {
  vpc_id      = aws_vpc.test.id
  description = "Allow MySQL from EC2 security group only"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web.id]
    description     = "MySQL from EC2 SG"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-rds-sg" }
}

# ----- DB Subnet Group -------------------------------------------------------

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private.id, aws_subnet.private_b.id]

  tags = { Name = "${local.name_prefix}-db-subnet-group" }
}

# ----- Random password za RDS ------------------------------------------------

resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ----- RDS MySQL instance ----------------------------------------------------

resource "aws_db_instance" "main" {
  identifier     = "${local.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.rds_db_name
  username = var.rds_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible  = false
  multi_az             = false # Dev — jedna AZ je dovoljna
  skip_final_snapshot  = true  # Dev — ne cuva snapshot na destroy
  deletion_protection  = false

  tags = { Name = "${local.name_prefix}-mysql" }
}

# ----- Secrets Manager — RDS kredencijali ------------------------------------
# Cuva username, password, host, port i connection string kao JSON.

resource "aws_secretsmanager_secret" "rds_credentials" {
  name                    = "${local.name_prefix}-rds-credentials-${random_id.secret_suffix.hex}"
  description             = "RDS MySQL credentials (managed by Terraform)"
  recovery_window_in_days = 0

  tags = { Name = "${local.name_prefix}-rds-credentials" }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username          = var.rds_username
    password          = random_password.db.result
    host              = aws_db_instance.main.address
    port              = aws_db_instance.main.port
    dbname            = var.rds_db_name
    connection_string = "mysql://${var.rds_username}:${random_password.db.result}@${aws_db_instance.main.address}:${aws_db_instance.main.port}/${var.rds_db_name}"
  })
}
