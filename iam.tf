# =============================================================================
# IAM – Identity resources (already created in AWS via bootstrap)
#
# Manages:
#   1. terraform-user  (programmatic IAM user)
#   2. TerraformAdminRole  (assume-role target)
#   3. TerraformS3BackendPolicy  (S3 backend + AssumeRole for user)
#   4. AdministratorAccess  (AWS managed policy on role)
#
# These resources were bootstrapped externally and imported into state.
# Critical resources have prevent_destroy so they are not accidentally removed.
# =============================================================================

# ----- 1. IAM User ----------------------------------------------------------

resource "aws_iam_user" "terraform" {
  name          = "terraform-user"
  force_destroy = true
  tags = {
    Name        = "terraform-user"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
    Project     = "terraform-zadaci"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_access_key" "terraform" {
  user = aws_iam_user.terraform.name
}

# ----- 2. IAM Role (TerraformAdminRole) -------------------------------------

resource "aws_iam_role" "terraform_admin" {
  name               = "TerraformAdminRole"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
  tags = {
    Name        = "TerraformAdminRole"
    Environment = "bootstrap"
    ManagedBy   = "Terraform"
    Project     = "terraform-zadaci"
  }

  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.terraform.arn]
    }
  }
}

# ----- 3. Role permissions (AdministratorAccess – AWS managed) ---------------

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ----- 4. User policy: S3 backend + AssumeRole (single combined policy) -----

data "aws_iam_policy_document" "backend_and_assume" {
  statement {
    sid       = "TerraformStateListBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }
  statement {
    sid = "TerraformStateReadWrite"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
    ]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/*"]
  }
  statement {
    sid       = "TerraformAssumeRole"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.terraform_admin.arn]
  }
}

resource "aws_iam_policy" "backend_and_assume" {
  name        = "TerraformS3BackendPolicy"
  description = "Policy for terraform-user to access S3 backend bucket and assume TerraformAdminRole"
  policy      = data.aws_iam_policy_document.backend_and_assume.json
}

resource "aws_iam_user_policy_attachment" "backend_and_assume" {
  user       = aws_iam_user.terraform.name
  policy_arn = aws_iam_policy.backend_and_assume.arn
}
