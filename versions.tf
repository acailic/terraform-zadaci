terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = "eu-north-1"
  profile = "terraform"

  assume_role {
    role_arn     = "arn:aws:iam::969578072702:role/TerraformAdminRole"
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}
