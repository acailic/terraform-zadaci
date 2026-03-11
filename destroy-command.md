###


terraform destroy \
  -target=aws_iam_access_key.terraform \
  -target=aws_iam_role_policy_attachment.admin \
  -target=aws_iam_user_policy_attachment.backend \
  -target=aws_iam_user_policy_attachment.assume_role \
  -target=aws_iam_policy.admin_permissions \
  -target=aws_iam_policy.backend_access \
  -target=aws_iam_policy.assume_role