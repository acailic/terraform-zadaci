output "terraform_user_arn" {
  description = "IAM user ARN used by Terraform for authentication."
  value       = aws_iam_user.terraform.arn
}

output "terraform_admin_role_arn" {
  description = "IAM role ARN assumed by Terraform for infrastructure changes."
  value       = aws_iam_role.terraform_admin.arn
}

output "terraform_backend_policy_arn" {
  description = "Combined S3 backend and AssumeRole policy attached to terraform-user."
  value       = aws_iam_policy.backend_and_assume.arn
}

output "terraform_access_key_id" {
  description = "Access key ID for the terraform-user profile."
  value       = aws_iam_access_key.terraform.id
}

output "terraform_access_key_secret" {
  description = "Retrieve once and store in the local AWS profile named terraform."
  value       = aws_iam_access_key.terraform.secret
  sensitive   = true
}
