# =============================================================================
# Bootstrap – IAM resources needed before Terraform can manage infrastructure
#
# Creates:
#   1. terraform-user  (programmatic IAM user)
#   2. TerraformAdminRole  (assume-role target for all infra work)
#   3. Policies: backend access, assume-role, admin permissions on the role
#
# This stack should rarely change. Use lifecycle { prevent_destroy } on
# critical resources so they are not accidentally removed.
# =============================================================================

# ----- 1. IAM User ----------------------------------------------------------

resource "aws_iam_user" "terraform" {
  name          = "terraform-user"
  force_destroy = true
  tags          = { Name = "terraform-user" }

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
  tags               = { Name = "TerraformAdminRole" }

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

# ----- 3. Role permissions ---------------------------------------------------
# Scoped to services Terraform actually manages. Expand as needed.

data "aws_iam_policy_document" "admin_permissions" {
  statement {
    sid = "ManageInfra"
    actions = [
      "ec2:*",
      "s3:*",
      "rds:*",
      "ecs:*",
      "eks:*",
      "cloudwatch:*",
      "logs:*",
      "iam:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "admin_permissions" {
  name   = "TerraformAdminPolicy"
  policy = data.aws_iam_policy_document.admin_permissions.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.terraform_admin.name
  policy_arn = aws_iam_policy.admin_permissions.arn
}

# ----- 4. User policy: S3 backend access ------------------------------------

data "aws_iam_policy_document" "backend_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}"]
  }
  statement {
    sid       = "ReadWriteState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:GetObjectVersion"]
    resources = ["arn:aws:s3:::${var.state_bucket_name}/*"]
  }
}

resource "aws_iam_policy" "backend_access" {
  name   = "TerraformBackendAccess"
  policy = data.aws_iam_policy_document.backend_access.json
}

resource "aws_iam_user_policy_attachment" "backend" {
  user       = aws_iam_user.terraform.name
  policy_arn = aws_iam_policy.backend_access.arn
}

# ----- 5. User policy: allow assuming TerraformAdminRole --------------------

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid       = "AssumeAdminRole"
    actions   = ["sts:AssumeRole"]
    resources = [aws_iam_role.terraform_admin.arn]
  }
}

resource "aws_iam_policy" "assume_role" {
  name   = "TerraformAssumeRole"
  policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_user_policy_attachment" "assume_role" {
  user       = aws_iam_user.terraform.name
  policy_arn = aws_iam_policy.assume_role.arn
}
