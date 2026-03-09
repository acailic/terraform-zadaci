# =============================================================================
# ZADATAK 1 – IAM setup
#
# Security model:
#   terraform-user  ─── credentials ───> S3 backend (state)
#                   ─── sts:AssumeRole ──> TerraformAdminRole ──> all resources
#
# The user NEVER touches resources directly. All infra goes through the role.
#
# BOOTSTRAP NOTE: The user + role are protected with prevent_destroy because
# Terraform NEEDS them to function. If you destroy them, Terraform can no
# longer assume the role and you're locked out.
# To tear down everything: first `terraform destroy` test resources, then
# delete the IAM user + role manually in the AWS console.
# =============================================================================

# ----- 1. IAM User (terraform-user) -----------------------------------------
# Programmatic-only user. Credentials are in ~/.aws/credentials [terraform].

resource "aws_iam_user" "terraform" {
  name          = "terraform-user"
  force_destroy = true
  tags          = { Name = "terraform-user" }

  lifecycle { prevent_destroy = true }
}

resource "aws_iam_access_key" "terraform" {
  user = aws_iam_user.terraform.name
}

# ----- 2. IAM Role (TerraformAdminRole) -------------------------------------
# The role that actually manages infrastructure.
# Trust policy: only terraform-user can assume this role.

resource "aws_iam_role" "terraform_admin" {
  name               = "TerraformAdminRole"
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
  tags               = { Name = "TerraformAdminRole" }

  lifecycle { prevent_destroy = true }
}

# Trust policy – WHO can assume the role
data "aws_iam_policy_document" "trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_user.terraform.arn]
    }
  }
}

# Permissions policy – WHAT the role can do
data "aws_iam_policy_document" "admin_permissions" {
  statement {
    sid       = "ManageInfra"
    actions   = ["ec2:*", "s3:*", "rds:*", "ecs:*", "eks:*", "cloudwatch:*", "logs:*", "iam:*", "elasticloadbalancing:*", "autoscaling:*"]
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

# ----- 3. User policy: S3 backend access (hardened, minimal) ----------------
# terraform-user needs direct S3 access ONLY for reading/writing state files.

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

# ----- 4. User policy: allow assuming TerraformAdminRole --------------------

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
