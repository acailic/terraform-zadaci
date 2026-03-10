# terraform-zadaci

Two-root Terraform layout separating **bootstrap** (identity / backend) from **infra** (application resources).

## Repository structure

```
bootstrap/          # IAM user, role, trust policy, backend access
infra/              # VPC, subnet, EC2, test S3 bucket (assumes TerraformAdminRole)
docs/               # Guides, plans, checklists
```

The old flat root files (`iam.tf`, `main.tf`, etc.) are kept for reference but are superseded by the two directories above.

## Workflow

### 1. Bootstrap (run once, or when IAM changes)

```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

This creates `terraform-user`, `TerraformAdminRole`, and the associated policies. Critical resources have `prevent_destroy` enabled.

### 2. Infra (day-to-day work)

```bash
cd infra
terraform init
terraform plan
terraform apply
```

This stack assumes `TerraformAdminRole` and provisions VPC, subnet, EC2, and a test S3 bucket.

### State files

| Stack     | S3 key                              |
|-----------|-------------------------------------|
| bootstrap | `terraform-zadaci/bootstrap.tfstate`|
| infra     | `terraform-zadaci/infra.tfstate`    |

## Authentication

Use the AWS default credential chain or a shared profile (`terraform`). Do not commit AWS access keys or secrets into the repository.

## Documentation

- **[Provider Versioning Guide](docs/provider-versioning.md)** - Comprehensive reference for Terraform provider version management
- [Zadatak 1 - IAM Setup](docs/zadatak1/zadatak1.md) - IAM user, role, and S3 backend configuration
