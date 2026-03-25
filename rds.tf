# =============================================================================
# RDS MySQL
#
# Free Tier: db.t3.micro, 20 GB, 750 sati/mesec (12 meseci).
# Baza je u private subnet-u, dostupna samo od EC2 instance (SG chaining).
# Kredencijali se cuvaju u Secrets Manager-u kao JSON.
# =============================================================================

# ----- RDS Security Group ----------------------------------------------------
# Dozvoljava MySQL (3306) samo od EC2 security grupe — security group chaining.

resource "aws_security_group" "rds" {
  count = local.create_rds ? 1 : 0

  vpc_id      = aws_vpc.test[0].id
  description = "Allow MySQL from EC2 security group only"

  dynamic "ingress" {
    for_each = local.create_ec2 ? [1] : []

    content {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [aws_security_group.web[0].id]
      description     = "MySQL from EC2 SG"
    }
  }

  dynamic "ingress" {
    for_each = length(var.rds_allowed_cidr_blocks) > 0 ? [var.rds_allowed_cidr_blocks] : []

    content {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      cidr_blocks = ingress.value
      description = "MySQL from configured CIDR blocks"
    }
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
  count = local.create_rds ? 1 : 0

  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.private[0].id, aws_subnet.private_b[0].id]

  tags = { Name = "${local.name_prefix}-db-subnet-group" }
}

# ----- Random password za RDS ------------------------------------------------

resource "random_password" "db" {
  count = local.create_rds ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# ----- RDS MySQL instance ----------------------------------------------------

resource "aws_db_instance" "main" {
  count = local.create_rds ? 1 : 0

  identifier     = "${local.name_prefix}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.rds_instance_class

  allocated_storage = 20
  storage_type      = "gp2"

  db_name  = var.rds_db_name
  username = var.rds_username
  password = random_password.db[0].result

  db_subnet_group_name   = aws_db_subnet_group.main[0].name
  vpc_security_group_ids = [aws_security_group.rds[0].id]

  publicly_accessible = false
  multi_az            = false # Dev — jedna AZ je dovoljna
  skip_final_snapshot = true  # Dev — ne cuva snapshot na destroy
  deletion_protection = false

  tags = { Name = "${local.name_prefix}-mysql" }
}

# ----- Secrets Manager — RDS kredencijali ------------------------------------
# Cuva username, password, host, port i connection string kao JSON.

resource "aws_secretsmanager_secret" "rds_credentials" {
  count = local.create_rds ? 1 : 0

  name                    = "${local.name_prefix}-rds-credentials-${random_id.secret_suffix[0].hex}"
  description             = "RDS MySQL credentials (managed by Terraform)"
  recovery_window_in_days = 0

  tags = { Name = "${local.name_prefix}-rds-credentials" }
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  count = local.create_rds ? 1 : 0

  secret_id = aws_secretsmanager_secret.rds_credentials[0].id
  secret_string = jsonencode({
    username          = var.rds_username
    password          = random_password.db[0].result
    host              = aws_db_instance.main[0].address
    port              = aws_db_instance.main[0].port
    dbname            = var.rds_db_name
    connection_string = "mysql://${var.rds_username}:${random_password.db[0].result}@${aws_db_instance.main[0].address}:${aws_db_instance.main[0].port}/${var.rds_db_name}"
  })
}
