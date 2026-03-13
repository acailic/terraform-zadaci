# Zadatak 1: IAM setup — terraform-user, TerraformAdminRole, S3 backend

## Cilj

Postaviti bezbedan Terraform workflow u AWS-u koristeci **assume role** model. Korisnik `terraform-user` sluzi samo za autentikaciju — svi resursi se kreiraju preko IAM role.

## Preduslovi

- Zavrsen Zadatak 0 (Terraform CLI, AWS CLI, AWS profil).
- Prava u AWS nalogu za kreiranje IAM korisnika, IAM rola i S3 bucket-a.

## Kontekst

Terraform ne treba da koristi kredencijale sa sirokim dozvolama. Umesto toga, koristi se **assume role** pattern — korisnik ima minimalne dozvole, a infrastrukturne operacije izvrsava kroz privremene kredencijale IAM role.

```text
terraform-user credentials
        |
        +--> S3 backend (state read/write)
        |
        +--> sts:AssumeRole --> TerraformAdminRole --> AWS resursi
```

## Zahtevi

### 1. IAM korisnik `terraform-user`

Kreirati IAM korisnika sa programmatic access-om. Korisnik treba da ima **samo** dve grupe dozvola:

- Minimalne S3 dozvole za citanje i pisanje Terraform state-a u backend bucket-u.
- Pravo da assume-uje `TerraformAdminRole`.

> Istrazi koje S3 akcije su potrebne da bi Terraform backend radio (citanje, pisanje, listanje, lock fajl).

### 2. IAM rola `TerraformAdminRole`

Kreirati IAM rolu sa:

- **Trust policy** koja dozvoljava `terraform-user` da uradi `sts:AssumeRole`.
- **Permission policy** sa dozvolama za servise koje Terraform treba da upravlja (EC2, VPC, S3, IAM, itd).

### 3. S3 backend bucket

Kreirati S3 bucket za Terraform state **van glavnog Terraform koda** (rucno ili kroz `bootstrap/`). Bucket mora imati:

- Versioning
- Server-side encryption
- Block public access

> Backend bucket je odvojen od test resursa koje Terraform kreira.

### 4. Provider konfiguracija

Konfigurisati Terraform provider da:

- Koristi lokalni AWS profil za autentikaciju.
- Koristi `assume_role` blok za sve infrastrukturne operacije.
- Backend konfiguraciju drzi u lokalnom fajlu koji se ne commit-uje.

## Isporuka

- [ ] `terraform-user` postoji sa programmatic access-om
- [ ] `terraform-user` ima samo backend i assume-role dozvole (nema direktan pristup EC2/VPC/...)
- [ ] `TerraformAdminRole` postoji sa trust policy-jem ka `terraform-user`
- [ ] S3 backend bucket ima versioning, enkripciju i block public access
- [ ] `terraform init` uspesno konfigurise backend
- [ ] `terraform apply` uspesno kreira test resurse (S3 bucket, VPC, EC2) kroz rolu

## Napomene

- Backend bucket ne moze sam sebe kreirati — mora postojati pre `terraform init`. Pogledaj `bootstrap/` direktorijum.
- Ako su IAM resursi vec kreirani rucno, koristi `terraform import` da ih uvezis u state.
- U produkciji zameni siroke policy-je granularnim sa ogranicenim `Resource` blokom.
- Razmotri `prevent_destroy` lifecycle blok na kriticnim IAM resursima.

## Korisni linkovi

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS STS AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [Terraform aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [Terraform Import](https://developer.hashicorp.com/terraform/cli/import)

