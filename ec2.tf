# =============================================================================
# EC2 – instance, SSH key pair, security group, user_data
# =============================================================================

# ----- Security Group -------------------------------------------------------

resource "aws_security_group" "web" {
  count = local.create_ec2 ? 1 : 0

  vpc_id      = aws_vpc.test[0].id
  description = "Allow SSH and HTTP inbound for NLB (NLB has no SG - passes client IP directly)"

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

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTP via NLB for web app"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.allowed_egress_cidr_blocks
  }

  tags = { Name = "${local.name_prefix}-web-sg" }
}

# ----- TLS Private Key + Secrets Manager -------------------------------------
# Generise SSH key par u Terraformu. Privatni kljuc se cuva u AWS Secrets Manager.
# Rotacija kljuceva je bitna — moze se automatizovati sa Lambda funkcijom.

resource "tls_private_key" "main" {
  count = local.create_ec2 ? 1 : 0

  algorithm = "ED25519"
}

resource "aws_key_pair" "main" {
  count = local.create_ec2 ? 1 : 0

  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.main[0].public_key_openssh

  tags = { Name = "${local.name_prefix}-key" }
}

resource "random_id" "secret_suffix" {
  count = local.create_ec2 || local.create_rds ? 1 : 0

  byte_length = 4
}

resource "aws_secretsmanager_secret" "ssh_private_key" {
  count = local.create_ec2 ? 1 : 0

  name                    = "${local.name_prefix}-ssh-private-key-${random_id.secret_suffix[0].hex}"
  description             = "SSH private key for EC2 instance access (managed by Terraform)"
  recovery_window_in_days = 0 # Dev environment — allow immediate deletion on destroy

  tags = { Name = "${local.name_prefix}-ssh-private-key" }
}

resource "aws_secretsmanager_secret_version" "ssh_private_key" {
  count = local.create_ec2 ? 1 : 0

  secret_id     = aws_secretsmanager_secret.ssh_private_key[0].id
  secret_string = tls_private_key.main[0].private_key_openssh
}

# ----- EC2 instance ---------------------------------------------------------

resource "aws_instance" "test" {
  count = local.create_ec2 ? 1 : 0

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.web[0].id]
  key_name               = aws_key_pair.main[0].key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_ssm[0].name

  # user_data runs on instance launch. The private subnet reaches the internet
  # via the NAT gateway in the public subnet.
  # AWS CLI cita RDS credentials iz Secrets Manager i cuva ih u /etc/db-credentials.json.
  # PHP web app cita taj fajl i prikazuje sadrzaj baze na web stranici.
  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail
    yum update -y
    yum install -y httpd mysql php php-mysqli php-json jq
    systemctl start httpd
    systemctl enable httpd

%{if local.create_rds}
    # --- Fetch RDS credentials from Secrets Manager via AWS CLI ----------------
    # EC2 instance role (ec2_secrets_read policy) allows GetSecretValue.
    # Credentials are saved to a local file — no copy-paste needed.
    REGION="${var.aws_region}"
    SECRET_ID="${aws_secretsmanager_secret.rds_credentials[0].name}"

    # Retry loop — Secrets Manager endpoint may take a moment after boot
    for i in $(seq 1 12); do
      if aws secretsmanager get-secret-value \
           --region "$REGION" \
           --secret-id "$SECRET_ID" \
           --query SecretString \
           --output text > /tmp/db-creds-raw.json 2>/dev/null; then
        break
      fi
      sleep 10
    done

    # Parse and save credentials as a clean JSON file readable by the web app
    DB_HOST=$(jq -r '.host'     /tmp/db-creds-raw.json)
    DB_PORT=$(jq -r '.port'     /tmp/db-creds-raw.json)
    DB_USER=$(jq -r '.username' /tmp/db-creds-raw.json)
    DB_PASS=$(jq -r '.password' /tmp/db-creds-raw.json)
    DB_NAME=$(jq -r '.dbname'   /tmp/db-creds-raw.json)

    # Save to /etc/db-credentials.json (readable only by root and apache)
    cat > /etc/db-credentials.json <<CREDS
    {
      "host": "$DB_HOST",
      "port": $DB_PORT,
      "username": "$DB_USER",
      "password": "$DB_PASS",
      "dbname": "$DB_NAME"
    }
    CREDS
    chmod 640 /etc/db-credentials.json
    chown root:apache /etc/db-credentials.json
    rm -f /tmp/db-creds-raw.json

    # Save connection string for CLI use (.my.cnf for passwordless mysql client)
    cat > /root/.my.cnf <<MYCNF
    [client]
    host=$DB_HOST
    port=$DB_PORT
    user=$DB_USER
    password=$DB_PASS
    database=$DB_NAME
    MYCNF
    chmod 600 /root/.my.cnf

    # Also save for ec2-user
    cp /root/.my.cnf /home/ec2-user/.my.cnf
    chown ec2-user:ec2-user /home/ec2-user/.my.cnf
    chmod 600 /home/ec2-user/.my.cnf

    # --- Static HTML landing page ---------------------------------------------
    echo "<h1>Hello from $(hostname -f)</h1><p><a href='/db.php'>View Database</a></p>" > /var/www/html/index.html

    # --- PHP web app — reads creds from file, connects to MySQL, shows data ---
    cat > /var/www/html/db.php <<'PHPEOF'
    <?php
    // Read DB credentials from local file (fetched from Secrets Manager at boot)
    $creds_file = '/etc/db-credentials.json';
    if (!file_exists($creds_file)) {
        die('<h1>Error</h1><p>DB credentials file not found. Waiting for init script to complete.</p>');
    }
    $creds = json_decode(file_get_contents($creds_file), true);
    if (!$creds) {
        die('<h1>Error</h1><p>Failed to parse DB credentials.</p>');
    }

    $conn = new mysqli($creds['host'], $creds['username'], $creds['password'], $creds['dbname'], $creds['port']);
    if ($conn->connect_error) {
        die('<h1>Connection Failed</h1><p>' . htmlspecialchars($conn->connect_error) . '</p>');
    }
    ?>
    <!DOCTYPE html>
    <html><head><title>DB Viewer</title>
    <style>
      body { font-family: sans-serif; margin: 2em; }
      table { border-collapse: collapse; margin: 1em 0; }
      th, td { border: 1px solid #ccc; padding: 6px 12px; text-align: left; }
      th { background: #f0f0f0; }
      h1 { color: #333; }
      .info { background: #e8f5e9; padding: 1em; border-radius: 4px; margin-bottom: 1em; }
    </style>
    </head><body>
    <h1>Database Viewer</h1>
    <div class="info">
      <strong>Host:</strong> <?= htmlspecialchars($creds['host']) ?><br>
      <strong>Database:</strong> <?= htmlspecialchars($creds['dbname']) ?><br>
      <strong>User:</strong> <?= htmlspecialchars($creds['username']) ?><br>
      <strong>Port:</strong> <?= htmlspecialchars($creds['port']) ?>
    </div>

    <?php
    // List all tables
    $tables_result = $conn->query('SHOW TABLES');
    if ($tables_result->num_rows === 0) {
        echo '<p>No tables found. Database is empty.</p>';
        echo '<p><em>Create a test table from the EC2 CLI:</em></p>';
        echo '<pre>mysql -e "CREATE TABLE demo (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP); INSERT INTO demo (name) VALUES (\"hello\"), (\"world\");"</pre>';
    } else {
        while ($table_row = $tables_result->fetch_row()) {
            $table_name = $table_row[0];
            echo '<h2>' . htmlspecialchars($table_name) . '</h2>';

            $data = $conn->query('SELECT * FROM `' . $conn->real_escape_string($table_name) . '` LIMIT 100');
            if ($data && $data->num_rows > 0) {
                echo '<table><tr>';
                $fields = $data->fetch_fields();
                foreach ($fields as $field) {
                    echo '<th>' . htmlspecialchars($field->name) . '</th>';
                }
                echo '</tr>';
                while ($row = $data->fetch_assoc()) {
                    echo '<tr>';
                    foreach ($row as $val) {
                        echo '<td>' . htmlspecialchars($val ?? 'NULL') . '</td>';
                    }
                    echo '</tr>';
                }
                echo '</table>';
            } else {
                echo '<p>Table is empty.</p>';
            }
        }
    }
    $conn->close();
    ?>
    <hr><p><a href="/">Back to home</a></p>
    </body></html>
    PHPEOF
%{else}
    echo "<h1>Hello from $(hostname -f)</h1><p>RDS stack is disabled for this environment.</p>" > /var/www/html/index.html
%{endif}

  EOF

  tags = { Name = "${local.name_prefix}-ec2" }
}
