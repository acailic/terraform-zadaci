terraform {
  backend "s3" {
    bucket  = "terraform-state-bucket-uddspring"
    key     = "terraform-zadaci/terraform.tfstate"
    region  = "us-east-1"
    profile = "terraform"
  }
}
