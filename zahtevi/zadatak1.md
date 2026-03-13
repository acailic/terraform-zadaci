# Zadatak 1: IAM setup — terraform-user, TerraformAdminRole, S3 backend

## Cilj

Postaviti bezbedan Terraform workflow u AWS-u koristeci **assume role** model:

- `terraform-user` — IAM korisnik koji se koristi samo za autentikaciju i pristup state backend-u.
- `TerraformAdminRole` — IAM rola sa dozvolama za kreiranje infrastrukture. Terraform je assume-uje.
- S3 backend — Terraform state se cuva u posebnom S3 bucket-u sa minimalnim dozvolama.

## Bezbednosni model

```text
terraform-user credentials
        |
        +--> S3 backend (state read/write + lock)
        |
        +--> sts:AssumeRole --> TerraformAdminRole --> AWS resursi (EC2, VPC, S3...)
```

`terraform-user` **nema** direktne dozvole za EC2, VPC, RDS i slicno — sve ide kroz rolu.

## Zahtevi

### 1. Kreirati IAM korisnika `terraform-user`

- Programmatic access (Access Key + Secret Key).
- Dodeliti **samo** dve grupe dozvola:
  - Pristup S3 state backend bucket-u (minimalne dozvole).
  - Pravo `sts:AssumeRole` nad `TerraformAdminRole`.

**Minimalne backend dozvole:**

| Dozvola | Nivo | Svrha |
|---------|------|-------|
| `s3:ListBucket` | Bucket | Provera da li state fajl postoji |
| `s3:GetObject` | Objekat | Citanje state-a |
| `s3:PutObject` | Objekat | Pisanje state-a |
| `s3:DeleteObject` | `.tflock` objekat | Brisanje lock fajla |
| `s3:GetObjectVersion` | Objekat | Opciono — za versioning |

> **Tip:** Koristi AWS profil (`aws configure --profile terraform`) ili environment varijable. Nikada ne hardkodirati kljuceve u `.tf` fajlove.

### 2. Kreirati IAM rolu `TerraformAdminRole`

- **Trust policy:** Dozvoljava `terraform-user` da uradi `sts:AssumeRole`.
- **Permission policy:** Dozvole za servise koje Terraform treba da upravlja (EC2, VPC, S3, IAM, CloudWatch, itd).

> **Napomena:** U ovom zadatku je dozvoljen siri scope dozvola radi vezbe. U produkciji koristiti granularne policy-je po servisu sa ogranicenim `Resource` blokom.

### 3. Kreirati S3 backend bucket (van Terraform koda)

Bucket za state se kreira **rucno** ili kroz poseban bootstrap Terraform (videti `bootstrap/` direktorijum).

Obavezno omoguciti:
- **Versioning** — zastita od slucajnog brisanja/prepisivanja state-a.
- **Server-side encryption** (AES256 ili KMS) — state moze sadrzati osetljive podatke.
- **Block public access** — state nikada ne sme biti javno dostupan.

> **Bitno:** Backend bucket je **odvojen** od test S3 bucket-a koji se kreira kroz Terraform (`aws_s3_bucket.test`).

### 4. Konfigurisati Terraform provider

- Provider koristi lokalni AWS profil (`var.aws_profile`).
- Provider koristi `assume_role` blok ka `TerraformAdminRole`.
- Backend konfiguracija se drzi u lokalnom `backend.hcl` fajlu (ne commit-ovati).

```bash
terraform init -backend-config=backend.hcl
```

### 5. Verifikacija

Potvrditi da Terraform moze da kreira test resurse preko role:

- [x] S3 bucket (nije backend bucket) — `aws_s3_bucket.test`
- [x] VPC + subnet — `aws_vpc.test`, `aws_subnet.public`
- [x] EC2 instancu — `aws_instance.test`

Ako ovo radi, assume-role model je ispravno postavljen.

## Koraci za implementaciju

1. Definisi IAM resurse u `iam.tf`:
   - `aws_iam_user.terraform_user`
   - `aws_iam_role.terraform_admin` sa trust policy-jem
   - Policy dokumenti za backend pristup i admin dozvole
2. Konfiguriši provider u `versions.tf` sa `assume_role` blokom.
3. Konfiguriši backend u `backend.tf`.
4. Pokreni `terraform init` i `terraform plan`.
5. Proveri da `terraform apply` uspesno kreira test resurse.

## Hardening nakon vezbe

- Zameni siroke policy-je **granularnim** policy-jima po servisu.
- Ogranici `Resource` gde god je moguce (ne koristiti `"*"` u produkciji).
- Rotiraj sve kljuceve koji su ikada bili izlozeni.
- Zadrzi versioning i enkripciju za state bucket.
- Razmotri dodavanje `prevent_destroy` lifecycle bloka na kriticne IAM resurse.

## Saveti

- **Least privilege:** Daj samo minimalne dozvole koje su potrebne. Lakse je dodati dozvole nego otkriti da imas previse.
- **State je osetljiv:** Terraform state moze sadrzati lozinke, kljuceve i druge tajne. Tretirati ga kao poverljiv podatak.
- **Bootstrap problem:** Backend bucket ne moze sam sebe kreirati — mora postojati pre `terraform init`. Koristi `bootstrap/` direktorijum ili rucno kreiranje.
- **Import:** Ako su IAM resursi vec kreirani rucno, koristi `terraform import` da ih uvezis u state. Videti `docs/import-guide.md`.

## Korisni linkovi

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS STS AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [Terraform Import](https://developer.hashicorp.com/terraform/cli/import)

