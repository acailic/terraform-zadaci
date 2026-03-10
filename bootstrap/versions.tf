terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Bootstrap assumes TerraformAdminRole to manage IAM resources.
# This creates a soft circular dependency (the role manages itself), but
# prevent_destroy on critical resources prevents accidental lockout.
provider "aws" {
  region  = var.aws_region
  profile = "terraform"

  assume_role {
    role_arn     = "arn:aws:iam::969578072702:role/TerraformAdminRole"
    session_name = "terraform-bootstrap"
  }

  default_tags {
    tags = {
      Environment = "bootstrap"
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  }
}
