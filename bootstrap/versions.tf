terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Bootstrap uses the terraform profile directly (IAM user credentials).
# It does NOT assume a role — it is creating the role.
provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  default_tags {
    tags = {
      Environment = "bootstrap"
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}
