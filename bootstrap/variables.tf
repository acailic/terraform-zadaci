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

variable "state_bucket_name" {
  description = "S3 bucket that stores Terraform state (created outside this config)."
  type        = string
  default     = "terraform-state-bucket-uddspring"
}
