variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
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

variable "state_bucket_name" {
  description = "S3 bucket that stores Terraform state (created outside this config)."
  type        = string
  default     = "terraform-state-bucket-uddspring"
}

# static AMI ID with a us-east-1-specific note, can be issue
variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023 in us-east-1 by default)."
  type        = string
  default     = "ami-02dfbd4ff395f2a1b"
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}
