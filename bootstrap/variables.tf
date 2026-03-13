variable "aws_region" {
  description = "AWS region for bootstrap operations."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional shared AWS CLI profile for bootstrap operations. Leave null to use environment credentials or the default AWS credential chain."
  type        = string
  default     = null
  nullable    = true
}

variable "project_name" {
  description = "Used in bootstrap tags."
  type        = string
  default     = "terraform-zadaci"
}

variable "environment" {
  description = "Environment tag for bootstrap resources."
  type        = string
  default     = "bootstrap"
}

variable "state_bucket_name" {
  description = "S3 bucket that stores Terraform state for the main infra stack."
  type        = string
  default     = "terraform-state-bucket-uddspring"
}

variable "terraform_user_name" {
  description = "IAM user used by Terraform for authentication."
  type        = string
  default     = "terraform-user"
}

variable "terraform_admin_role_name" {
  description = "IAM role assumed by the terraform user for infrastructure work."
  type        = string
  default     = "TerraformAdminRole"
}

variable "backend_policy_name" {
  description = "Combined S3 backend + AssumeRole policy name attached to terraform-user."
  type        = string
  default     = "TerraformS3BackendPolicy"
}

variable "admin_policy_arn" {
  description = "Policy attached to TerraformAdminRole."
  type        = string
  default     = "arn:aws:iam::aws:policy/AdministratorAccess"
}
