## Terraform IAM i backend napomene

Credentiali ne treba da budu zapisani u repozitorijumu. Koristi lokalni `aws configure --profile terraform` ili environment varijable, a sve ranije izložene access key vrijednosti rotiraj odmah.

### AWS CLI konfiguracija

```bash
aws configure --profile terraform
```

### Backend konfiguracija

Repo sada koristi parcijalni S3 backend. Stvarne vrijednosti stavi u lokalni `backend.hcl` fajl na osnovu `backend.hcl.example`, pa inicijalizuj:

```bash
terraform init -backend-config=backend.hcl
```

Potrebne S3 permisije za backend su:

- `s3:ListBucket` na state bucket-u
- `s3:GetObject` i `s3:PutObject` na state fajlu
- `s3:GetObject`, `s3:PutObject` i `s3:DeleteObject` na `.tflock` fajlu kada je `use_lockfile = true`

### Assume role

Ako koristiš role assumption, postavi `assume_role_arn` kroz `terraform.tfvars` ili preko AWS shared config profila, umjesto da role ARN bude hardkodiran u provider bloku.

### Hardening

- ukloni široke privilegije kao što je `AdministratorAccess`
- koristi granularne IAM policy-je po servisu
- zadrži bucket versioning i backend encryption uključene zbog state recovery-ja
