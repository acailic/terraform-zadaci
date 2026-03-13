###


terraform destroy \
  -target=aws_iam_access_key.terraform \
  -target=aws_iam_role_policy_attachment.admin \
  -target=aws_iam_user_policy_attachment.backend \
  -target=aws_iam_user_policy_attachment.assume_role \
  -target=aws_iam_policy.admin_permissions \
  -target=aws_iam_policy.backend_access \
  -target=aws_iam_policy.assume_role


terraform destroy \
  -target=aws_instance.test \
  -target=aws_security_group.web \
  -target=aws_route_table_association.public \
  -target=aws_route_table.public \
  -target=aws_internet_gateway.main \
  -target=aws_subnet.public \
  -target=aws_vpc.test \
  -target=aws_s3_bucket_public_access_block.test \
  -target=aws_s3_bucket_server_side_encryption_configuration.test \
  -target=aws_s3_bucket_versioning.test \
  -target=aws_s3_bucket.test
