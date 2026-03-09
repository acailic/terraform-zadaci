# The provider authenticates as terraform-user (via profile),
# then assumes TerraformAdminRole for all resource operations.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  assume_role {
    role_arn     = var.assume_role_arn
    session_name = "terraform-session"
  }

  default_tags {
    tags = local.default_tags
  }
}
