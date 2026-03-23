#!/bin/bash

# S3 — pokrenuti iz SSM sesije na EC2
echo "hello from ec2" > /tmp/test.txt
aws s3 cp /tmp/test.txt s3://terraform-zadaci-dev-test-bucket/test.txt
aws s3 ls s3://terraform-zadaci-dev-test-bucket/
aws s3 cp s3://terraform-zadaci-dev-test-bucket/test.txt /tmp/downloaded.txt
cat /tmp/downloaded.txt
aws s3 rm s3://terraform-zadaci-dev-test-bucket/test.txt

# SSH kljuc
SECRET_ARN=$(terraform output -raw ssh_private_key_secret_arn)
aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --query SecretString \
  --output text > ~/.ssh/terraform-zadaci-key
chmod 600 ~/.ssh/terraform-zadaci-key
### 644 je public readable, 600 private readable
# SSM port forwarding — Terminal 1
INSTANCE_ID=$(terraform output -raw test_ec2_instance_id)
aws ssm start-session \
  --target "$INSTANCE_ID" \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}'

# SSH kroz tunel — Terminal 2
ssh -i ~/.ssh/terraform-zadaci-key \
    -p 2222 \
    -o StrictHostKeyChecking=no \
    ec2-user@localhost

# Direktan SSH (zahteva ~/.ssh/config sa ProxyCommand)
ssh i-0abc123def456789

# =============================================================================
# RDS — Fetch DB credentials from Secrets Manager (no copy-paste)
# =============================================================================

# Fetch RDS credentials secret ARN from Terraform output
RDS_SECRET_ARN=$(terraform output -raw rds_credentials_secret_arn)

# Retrieve the full JSON credentials
aws secretsmanager get-secret-value \
  --secret-id "$RDS_SECRET_ARN" \
  --query SecretString \
  --output text | jq .

# Save connection info to a local file for reuse
aws secretsmanager get-secret-value \
  --secret-id "$RDS_SECRET_ARN" \
  --query SecretString \
  --output text > /tmp/rds-creds.json

# Extract individual fields
DB_HOST=$(jq -r '.host' /tmp/rds-creds.json)
DB_PORT=$(jq -r '.port' /tmp/rds-creds.json)
DB_USER=$(jq -r '.username' /tmp/rds-creds.json)
DB_PASS=$(jq -r '.password' /tmp/rds-creds.json)
DB_NAME=$(jq -r '.dbname' /tmp/rds-creds.json)

# Connect to MySQL using extracted credentials (no copy-paste of password)
mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" -p"$DB_PASS" "$DB_NAME"

# --- Na EC2 instanci (after user_data runs, credentials are already saved) ---
# mysql klijent koristi /home/ec2-user/.my.cnf automatski — samo pokreni:
mysql
mysql -e "SHOW DATABASES;"
mysql -e "CREATE TABLE demo (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);"
mysql -e "INSERT INTO demo (name) VALUES ('hello'), ('world');"
mysql -e "SELECT * FROM demo;"

# Web app pristup — otvori u browseru:
echo "http://$(terraform output -raw nlb_dns_name)/db.php"
