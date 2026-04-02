output "test_bucket_name" {
  value = try(aws_s3_bucket.test[0].bucket, null)
}

output "test_vpc_id" {
  value = try(aws_vpc.test[0].id, null)
}

# Scalar outputs — backward compatible with existing scripts (05-commands.sh, etc.)
output "test_ec2_instance_id" {
  value = try(aws_instance.test[0].id, null)
}

output "test_ec2_private_ip" {
  description = "Private IP of the first EC2 instance in the private subnet."
  value       = try(aws_instance.test[0].private_ip, null)
}

# List outputs — all EC2 instances (1 or 2 depending on ALB)
output "test_ec2_instance_ids" {
  description = "IDs of all EC2 instances."
  value       = aws_instance.test[*].id
}

output "test_ec2_private_ips" {
  description = "Private IPs of all EC2 instances."
  value       = aws_instance.test[*].private_ip
}

output "internet_gateway_id" {
  value = try(aws_internet_gateway.main[0].id, null)
}

output "ec2_ssm_role_arn" {
  description = "EC2 instance profile role — provides SSM Agent credentials (not root)."
  value       = try(aws_iam_role.ec2_ssm[0].arn, null)
}

output "key_pair_name" {
  value = try(aws_key_pair.main[0].key_name, null)
}

output "private_subnet_id" {
  description = "ID of the private subnet."
  value       = try(aws_subnet.private[0].id, null)
}

output "ssh_private_key_secret_arn" {
  description = "ARN of the Secrets Manager secret storing the SSH private key."
  value       = try(aws_secretsmanager_secret.ssh_private_key[0].arn, null)
}

output "vpce_ssm_ids" {
  description = "IDs of the SSM VPC endpoints."
  value       = { for k, v in aws_vpc_endpoint.ssm : k => v.id }
}

output "nat_gateway_id" {
  description = "ID of the NAT gateway in the public subnet."
  value       = try(aws_nat_gateway.main[0].id, null)
}

output "nat_gateway_public_ip" {
  description = "Public IP of the NAT gateway (Elastic IP)."
  value       = try(aws_eip.nat[0].public_ip, null)
}

output "ec2_s3_policy_arn" {
  description = "ARN of the IAM policy granting EC2 S3 access."
  value       = try(aws_iam_policy.ec2_s3_access[0].arn, null)
}

output "s3_gateway_endpoint_id" {
  description = "ID of the S3 Gateway VPC endpoint."
  value       = try(aws_vpc_endpoint.s3[0].id, null)
}

# ----- ALB outputs -----------------------------------------------------------

output "alb_dns_name" {
  description = "Public DNS of the ALB — open this in browser to see your web server."
  value       = try(aws_lb.alb[0].dns_name, null)
}

output "alb_web_url" {
  description = "Web app URL via ALB — points to /db.php when RDS is active, otherwise /."
  value       = try("http://${aws_lb.alb[0].dns_name}${var.create_rds ? "/db.php" : "/"}", null)
}

# ----- DNS outputs -----------------------------------------------------------

output "route53_nameservers" {
  description = "NS servers to configure at your domain registrar for DNS delegation."
  value       = try(aws_route53_zone.main[0].name_servers, null)
}

output "route53_zone_id" {
  description = "Route 53 hosted zone ID."
  value       = try(aws_route53_zone.main[0].zone_id, null)
}

output "custom_domain_url" {
  description = "Web app URL via custom domain (HTTPS when DNS is active)."
  value       = local.create_dns ? "https://${var.domain_name}" : null
}

output "acm_certificate_arn" {
  description = "ARN of the ACM SSL certificate for the custom domain."
  value       = try(aws_acm_certificate.main[0].arn, null)
}

# NLB outputs — hardcoded null while NLB is commented out (backward compatible)
output "nlb_dns_name" {
  description = "Public DNS of the NLB (NLB currently disabled — using ALB)."
  value       = null
}

output "nlb_ssh_command" {
  description = "SSH command via NLB (NLB currently disabled — using ALB)."
  value       = null
}

output "nlb_web_url" {
  description = "Web app URL via NLB (NLB currently disabled — using ALB)."
  value       = null
}

# ----- RDS outputs -----------------------------------------------------------

output "rds_endpoint" {
  description = "RDS MySQL endpoint (host:port)."
  value       = try(aws_db_instance.main[0].endpoint, null)
}

output "rds_address" {
  description = "RDS MySQL hostname (without port)."
  value       = try(aws_db_instance.main[0].address, null)
}

output "rds_credentials_secret_arn" {
  description = "ARN of the Secrets Manager secret storing RDS credentials."
  value       = try(aws_secretsmanager_secret.rds_credentials[0].arn, null)
}

output "rds_mysql_command" {
  description = "MySQL connect command (run from EC2 instance, retrieve password from Secrets Manager)."
  value       = try("mysql -h ${aws_db_instance.main[0].address} -u ${var.rds_username} -p ${var.rds_db_name}", null)
}
