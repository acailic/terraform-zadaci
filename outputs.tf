output "test_bucket_name" {
  value = aws_s3_bucket.test.bucket
}

output "test_vpc_id" {
  value = aws_vpc.test.id
}

output "test_ec2_instance_id" {
  value = aws_instance.test.id
}

output "test_ec2_public_ip" {
  value = aws_instance.test.public_ip
}

output "internet_gateway_id" {
  value = aws_internet_gateway.main.id
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
