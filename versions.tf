terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Single-root stack — authenticates as terraform-user, then assumes
# TerraformAdminRole for all resource operations.
provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  assume_role {
    role_arn     = "arn:aws:iam::969578072702:role/TerraformAdminRole"
    session_name = "TerraformSession"
  }

  default_tags {
    tags = local.default_tags
  }
}
