terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-uddspring"
    key            = "terraform-zadaci/root.tfstate"
    region         = "us-east-1"
    profile        = "terraform"
    # encrypt        = true
    # dynamodb_table = "terraform-locks"
     # use_lockfile = true
  }
}

 