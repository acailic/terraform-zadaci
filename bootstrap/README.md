# Bootstrap stack

This Terraform root creates the IAM objects that usually have to exist before
the main Terraform configuration can run:

- `terraform-user`
- `TerraformAdminRole`
- `TerraformS3BackendPolicy`
- access key for `terraform-user`

## Usage

Use direct AWS credentials with IAM permissions. The bootstrap provider now
accepts an explicit shared AWS profile via `aws_profile`, or it can still use
temporary credentials from the environment. This stack uses the local backend
by default, so it does not depend on the `terraform` AWS profile already
existing.

```bash
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -var='aws_profile=admin'
terraform -chdir=bootstrap apply -var='aws_profile=admin'
```

If you prefer not to pass `-var` each time, create `bootstrap/terraform.tfvars`
with:

```hcl
aws_profile = "admin"
```

After apply, put the generated access key into the local `terraform` profile:

```bash
terraform -chdir=bootstrap output -raw terraform_access_key_id
terraform -chdir=bootstrap output -raw terraform_access_key_secret
aws configure --profile terraform
```

Then return to the repo root and run the main infrastructure stack.

If `terraform-user`, `TerraformAdminRole`, or the policy already exist because
they were created manually in the console, import them into this stack instead
of recreating them. See `../docs/import-guide.md`.
