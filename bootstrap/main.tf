# =============================================================================
# Bootstrap IAM stack
#
# Creates the pieces that are otherwise usually clicked together in the AWS
# console before Terraform can manage the rest of the infrastructure:
#   1. terraform-user
#   2. TerraformAdminRole
#   3. TerraformS3BackendPolicy
#   4. An access key for terraform-user
# =============================================================================

resource "aws_iam_user" "terraform" {
  name          = var.terraform_user_name
  force_destroy = true

  tags = merge(local.default_tags, {
    Name = var.terraform_user_name
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_access_key" "terraform" {
  user = aws_iam_user.terraform.name
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

resource "aws_iam_role" "terraform_admin" {
  name               = var.terraform_admin_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json

  tags = merge(local.default_tags, {
    Name = var.terraform_admin_role_name
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = var.admin_policy_arn
}

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
  name        = var.backend_policy_name
  description = "Allows terraform-user to access the state bucket and assume TerraformAdminRole"
  policy      = data.aws_iam_policy_document.backend_and_assume.json
}

resource "aws_iam_user_policy_attachment" "backend_and_assume" {
  user       = aws_iam_user.terraform.name
  policy_arn = aws_iam_policy.backend_and_assume.arn
}
