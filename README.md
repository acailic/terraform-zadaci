# terraform-zadaci

This root module creates a hardened S3 bucket and uses a partial S3 backend configuration.

## Usage

1. Create a local backend config from `backend.hcl.example`.
2. Create a local variables file from `terraform.tfvars.example`.
3. Initialize Terraform:

```bash
terraform init -backend-config=backend.hcl
```

4. Review the plan:

```bash
terraform plan
```

## Authentication

Use the AWS default credential chain or a shared profile. Do not commit AWS access keys or secrets into the repository.

If you need to assume a role, set `assume_role_arn` in `terraform.tfvars` or configure role assumption in your AWS profile.

## Backend permissions

The S3 backend needs:

- `s3:ListBucket` on the backend bucket
- `s3:GetObject` and `s3:PutObject` on the state object
- `s3:GetObject`, `s3:PutObject`, and `s3:DeleteObject` on the `.tflock` object when `use_lockfile = true`

## Documentation

- **[Provider Versioning Guide](docs/provider-versioning.md)** - Comprehensive reference for Terraform provider version management
- [Zadatak 1 - IAM Setup](docs/zadatak1/zadatak1.md) - IAM user, role, and S3 backend configuration
