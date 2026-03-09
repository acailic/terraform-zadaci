Zadatak 1 Checklist
#	Requirement	Status	Where
1	IAM korisnik terraform-user sa programmatic access	✅	iam.tf:20-30 — user + access key
1a	User ne upravlja infra direktno — samo assume role	✅	provider.tf:3 — provider uses assume_role
1b	Direktan pristup samo za backend: ListBucket, GetObject, PutObject	✅	iam.tf:82-95 — hardened policy
1c	GetObjectVersion (optional za versioning)	✅	iam.tf:91 — included
1d	Credentials via CLI profile (ne hardkodiran)	✅	provider.tf:5 — profile = var.aws_profile
2	IAM rola TerraformAdminRole	✅	iam.tf:37-42
2a	Privilegije: VPC, EC2, S3, RDS, ECS, EKS, CloudWatch	✅	iam.tf:57-62 — all services listed
2b	Trust Relationship: terraform-user može assume	✅	iam.tf:45-53 — trust policy
3	S3 bucket za Terraform state	✅	Created outside Terraform (console), referenced in backend.hcl.example
3a	Versioning aktivan	⚠️	Must verify in console — state bucket is NOT managed by this config
4	Provider: profil za S3 backend + assume role za resurse	✅	provider.tf:3-14
4a	Test: S3 bucket (resource)	✅	main.tf:13-19
4b	Test: EC2 instanca	✅	main.tf:75-81
4c	Test: VPC	✅	main.tf:44-50
5	Hardening: minimalne S3 polise	✅	iam.tf:82-95 — only ListBucket, Get/Put/Delete Object, GetObjectVersion