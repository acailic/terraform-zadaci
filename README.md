# terraform-zadaci

Single-root Terraform configuration managing IAM, networking, and application resources.

## Repository structure

```
*.tf                # Terraform configuration (IAM, VPC, subnet, EC2, S3)
docs/               # Guides, plans, checklists
```

## Workflow

```bash
terraform init
terraform plan
terraform apply
```

This provisions IAM resources (terraform-user, TerraformAdminRole, policies), VPC, public subnet with Internet Gateway, EC2 with user_data, and a test S3 bucket. Critical IAM resources have `prevent_destroy` enabled.

### State file

| Stack | S3 key                               |
|-------|--------------------------------------|
| infra | `terraform-zadaci/terraform.tfstate` |

## Authentication

Use the AWS default credential chain or a shared profile (`terraform`). Do not commit AWS access keys or secrets into the repository.

## Documentation

- **[Import Guide](docs/import-guide.md)** - Prerequisites and commands for importing pre-existing IAM resources into state
- **[Provider Versioning Guide](docs/provider-versioning.md)** - Comprehensive reference for Terraform provider version management
- [Zadatak 1 - IAM Setup](docs/zadatak1/zadatak1.md) - IAM user, role, and S3 backend configuration


#### 

- [x] dodati internet gateway (`aws_internet_gateway.main`)
- [x] public subnet (`map_public_ip_on_launch = true` + route table 0.0.0.0/0 → IGW)
- [x] srediti varijable — `ami_id` i `instance_type` su sada u `variables.tf`
- [x] CIDR: VPC `10.0.0.0/16` (65 536 IPs), Subnet `10.0.1.0/24` (256 IPs: 10.0.1.0–10.0.1.255)
- [x] EC2 `user_data` — bash script instalira httpd i postavlja index stranicu
