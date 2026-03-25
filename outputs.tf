output "test_bucket_name" {
  value = try(aws_s3_bucket.test[0].bucket, null)
}

output "test_vpc_id" {
  value = try(aws_vpc.test[0].id, null)
}

output "test_ec2_instance_id" {
  value = try(aws_instance.test[0].id, null)
}

output "test_ec2_private_ip" {
  description = "Private IP of the EC2 instance in the private subnet."
  value       = try(aws_instance.test[0].private_ip, null)
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
  value       = try(aws_lb.nlb[0].dns_name, null)
}

output "nlb_ssh_command" {
  description = "SSH command via NLB (retrieve key from Secrets Manager first)."
  value       = try("ssh -i private-key.pem ec2-user@${aws_lb.nlb[0].dns_name}", null)
}

output "nlb_web_url" {
  description = "Web app URL via NLB — open in browser to see DB viewer."
  value       = try("http://${aws_lb.nlb[0].dns_name}/db.php", null)
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
