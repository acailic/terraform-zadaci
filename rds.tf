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
