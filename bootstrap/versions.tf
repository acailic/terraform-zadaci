terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Bootstrap must use direct AWS credentials with IAM permissions. Do not assume
# TerraformAdminRole here because this stack creates that role.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.default_tags
  }
}
