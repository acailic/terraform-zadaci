terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Infra stack assumes TerraformAdminRole created by bootstrap.
provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  assume_role {
    role_arn     = var.terraform_admin_role_arn
    session_name = "terraform-infra"
  }

  default_tags {
    tags = local.default_tags
  }
}
