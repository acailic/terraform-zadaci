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
