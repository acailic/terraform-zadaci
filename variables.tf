# --- Provider ---

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "AWS CLI profile name (matches [profile X] in ~/.aws/config)."
  type        = string
  default     = "terraform"
}

variable "assume_role_arn" {
  description = "ARN of the IAM role the provider assumes for resource management."
  type        = string
}

# --- Naming ---

variable "project_name" {
  description = "Used in resource names and tags."
  type        = string
  default     = "terraform-zadaci"
}

variable "environment" {
  description = "e.g. dev, staging, prod — used in names and tags."
  type        = string
  default     = "dev"
}

# --- State backend ---

variable "state_bucket_name" {
  description = "S3 bucket that stores Terraform state (created outside this config)."
  type        = string
  default     = "terraform-state-bucket-uddspring"
}
