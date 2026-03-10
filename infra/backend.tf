terraform {
  backend "s3" {
    bucket  = "terraform-state-bucket-uddspring"
    key     = "terraform-zadaci/infra.tfstate"
    region  = "us-east-1"
    profile = "terraform"
  }
}
