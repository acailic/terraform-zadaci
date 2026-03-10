# Outputs consumed by the infra stack (via data source or manual config).

output "terraform_user_arn" {
  value = aws_iam_user.terraform.arn
}

output "terraform_admin_role_arn" {
  value = aws_iam_role.terraform_admin.arn
}

# Access key ID is safe to output; the secret is intentionally omitted.
# Retrieve the secret once via `terraform output -raw terraform_access_key_secret`
# after initial bootstrap, then store it in your AWS CLI profile.
output "terraform_access_key_id" {
  value = aws_iam_access_key.terraform.id
}

output "terraform_access_key_secret" {
  description = "Retrieve once after bootstrap, then rotate. Do not store in VCS."
  value       = aws_iam_access_key.terraform.secret
  sensitive   = true
}
