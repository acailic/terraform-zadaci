terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Single-root stack — uses the terraform profile directly.
provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  default_tags {
    tags = local.default_tags
  }
}
