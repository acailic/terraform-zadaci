output "test_bucket_name" {
  value = aws_s3_bucket.test.bucket
}

output "test_vpc_id" {
  value = aws_vpc.test.id
}

output "test_ec2_instance_id" {
  value = aws_instance.test.id
}

output "test_ec2_private_ip" {
  description = "Private IP of the EC2 instance in the private subnet."
  value       = aws_instance.test.private_ip
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
}

output "ec2_ssm_role_arn" {
  description = "EC2 instance profile role — provides SSM Agent credentials (not root)."
  value       = aws_iam_role.ec2_ssm.arn
}

output "key_pair_name" {
  value = aws_key_pair.main.key_name
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = aws_subnet.private.id
}

output "ssh_private_key_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the SSH private key."
  value       = aws_secretsmanager_secret.ssh_private_key.arn
}

output "vpce_ssm_ids" {
  description = "IDs of the SSM VPC endpoints."
  value       = { for k, v in aws_vpc_endpoint.ssm : k => v.id }
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway in the public subnet."
  value       = aws_nat_gateway.main.id
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT gateway (Elastic IP)."
  value       = aws_eip.nat.public_ip
}

output "ec2_s3_policy_arn" {
  description = "ARN of the IAM policy granting EC2 S3 access."
  value       = aws_iam_policy.ec2_s3_access.arn
}

output "s3_gateway_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint."
  value       = aws_vpc_endpoint.s3.id
}

# ALB outputs (zakomentarisan — option b: NLB)
# output "alb_dns_name" {
#   description = "Public DNS of the ALB — open this in browser to see your web server."
#   value       = aws_lb.main.dns_name
# }
#
# output "alb_url" {
#   description = "Full URL to access the web server via ALB."
#   value       = "http://${aws_lb.main.dns_name}"
# }

output "nlb_dns_name" {
  description = "Public DNS of the NLB — use for SSH: ssh -i key ec2-user@<nlb_dns>"
  value       = aws_lb.nlb.dns_name
}

output "nlb_ssh_command" {
  description = "SSH command via NLB (retrieve key from Secrets Manager first)."
  value       = "ssh -i private-key.pem ec2-user@${aws_lb.nlb.dns_name}"
}

output "nlb_web_url" {
  description = "Web app URL via NLB — open in browser to see DB viewer."
  value       = "http://${aws_lb.nlb.dns_name}/db.php"
}

# ----- RDS outputs -----------------------------------------------------------

output "rds_endpoint" {
  description = "RDS MySQL endpoint (host:port)."
  value       = aws_db_instance.main.endpoint
}

output "rds_address" {
  description = "RDS MySQL hostname (without port)."
  value       = aws_db_instance.main.address
}

output "rds_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret storing RDS credentials."
  value       = aws_secretsmanager_secret.rds_credentials.arn
}

output "rds_mysql_command" {
  description = "MySQL connect command (run from EC2 instance, retrieve password from Secrets Manager)."
  value       = "mysql -h ${aws_db_instance.main.address} -u ${var.rds_username} -p ${var.rds_db_name}"
}
