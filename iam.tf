# =============================================================================
# IAM – EC2 instance role, policies, and instance profile
# =============================================================================

resource "aws_iam_role" "ec2_ssm" {
  count = local.create_iam ? 1 : 0

  name = "${local.name_prefix}-ec2-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = { Name = "${local.name_prefix}-ec2-ssm-role" }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  count = local.create_iam ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm" {
  count = local.create_iam ? 1 : 0

  name = "${local.name_prefix}-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm[0].name

  tags = { Name = "${local.name_prefix}-ec2-ssm-profile" }
}

# ----- S3 access policy for EC2 -----------------------------------------------

resource "aws_iam_policy" "ec2_s3_access" {
  count = local.create_iam && local.create_s3_bucket ? 1 : 0

  name        = "${local.name_prefix}-ec2-s3-access"
  description = "Allow EC2 instance to read/write the test S3 bucket."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListBucket"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = [aws_s3_bucket.test[0].arn]
      },
      {
        Sid    = "ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = ["${aws_s3_bucket.test[0].arn}/*"]
      },
    ]
  })

  tags = { Name = "${local.name_prefix}-ec2-s3-access" }
}

resource "aws_iam_role_policy_attachment" "ec2_s3_access" {
  count = local.create_iam && local.create_s3_bucket ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = aws_iam_policy.ec2_s3_access[0].arn
}

# ----- Secrets Manager read policy for EC2 ------------------------------------

resource "aws_iam_policy" "ec2_secrets_read" {
  count = local.create_iam && local.create_rds ? 1 : 0

  name        = "${local.name_prefix}-ec2-secrets-read"
  description = "Allow EC2 instance to read RDS credentials from Secrets Manager."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadRdsSecret"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        Resource = [aws_secretsmanager_secret.rds_credentials[0].arn]
      },
    ]
  })

  tags = { Name = "${local.name_prefix}-ec2-secrets-read" }
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_read" {
  count = local.create_iam && local.create_rds ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = aws_iam_policy.ec2_secrets_read[0].arn
}
