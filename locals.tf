# Common prefix for naming resources: "terraform-zadaci-dev"
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  default_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}
