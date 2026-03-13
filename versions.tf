terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Single-root stack — authenticates as terraform-user, then assumes
# TerraformAdminRole for all resource operations.
provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  assume_role {
    role_arn     = "arn:aws:iam::${var.aws_account_id}:role/TerraformAdminRole"
    session_name = "TerraformSession"
  }

  default_tags {
    tags = local.default_tags
  }
}
