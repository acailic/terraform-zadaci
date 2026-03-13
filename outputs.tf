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

# ----- IAM outputs -----------------------------------------------------------

output "terraform_user_arn" {
  value = aws_iam_user.terraform.arn
}

output "terraform_admin_role_arn" {
  value = aws_iam_role.terraform_admin.arn
}

output "terraform_access_key_id" {
  value = aws_iam_access_key.terraform.id
}


# Security risk, in s3 state can be viewed
output "terraform_access_key_secret" {
  description = "Retrieve once after bootstrap, then rotate. Do not store in VCS."
  value       = aws_iam_access_key.terraform.secret
  sensitive   = true
}
