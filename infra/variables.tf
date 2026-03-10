variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "eu-north-1"
}

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

variable "terraform_admin_role_arn" {
  description = "ARN of TerraformAdminRole created by the bootstrap stack."
  type        = string
  default     = "arn:aws:iam::969578072702:role/TerraformAdminRole"
}
