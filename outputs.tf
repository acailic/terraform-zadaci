# --- IAM ---

output "terraform_user_arn" {
  value = aws_iam_user.terraform.arn
}

output "terraform_admin_role_arn" {
  value = aws_iam_role.terraform_admin.arn
}

output "terraform_access_key_id" {
  value = aws_iam_access_key.terraform.id
}

output "terraform_access_key_secret" {
  value     = aws_iam_access_key.terraform.secret
  sensitive = true
}

# --- Test resources ---

output "test_bucket_name" {
  value = aws_s3_bucket.test.bucket
}

output "test_vpc_id" {
  value = aws_vpc.test.id
}

output "test_ec2_instance_id" {
  value = aws_instance.test.id
}
