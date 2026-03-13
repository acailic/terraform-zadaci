# Zadatak 1: IAM setup — terraform-user, TerraformAdminRole, S3 backend

## Cilj

Tvoj zadatak je da postavis IAM model u kome Terraform ne koristi siroke korisnicke dozvole, vec radi kroz **assume role** pristup.

## Preduslovi

- Zavrsen Zadatak 0
- Dovoljna prava u AWS nalogu za IAM i S3

## Tvoj zadatak

1. Kreiraj IAM korisnika `terraform-user` za programski pristup.
2. Ogranici `terraform-user` na samo dve vrste dozvola:
   - pristup S3 backend bucket-u za Terraform state
   - pravo da assume-uje `TerraformAdminRole`
3. Kreiraj IAM rolu `TerraformAdminRole` koju `terraform-user` moze da assume-uje.
4. Dodeli toj roli dozvole potrebne da Terraform upravlja resursima u ovom projektu.
5. Kreiraj poseban S3 bucket za Terraform state van glavne Terraform konfiguracije.
6. Konfigurisi Terraform tako da koristi lokalni AWS profil za autentikaciju, a rolu za infrastrukturne operacije.
7. Konfigurisi S3 backend sa partial konfiguracijskim fajlom (`-backend-config`).
8. Kreiraj test resurse (VPC, public subnet, Internet Gateway, Security Group, EC2 instancu, S3 bucket) da verifikujes da assume-role model radi.

## Isporuka

- [ ] `terraform-user` postoji i ima programski pristup
- [ ] `terraform-user` nema direktne dozvole za upravljanje infrastrukturom
- [ ] `TerraformAdminRole` postoji i trust policy dozvoljava assume role od strane `terraform-user`
- [ ] Backend bucket postoji i ima versioning, enkripciju i block public access
- [ ] S3 backend je konfigurisan sa partial config fajlom (`backend.hcl`)
- [ ] `terraform init` uspesno konfigurise backend
- [ ] Test VPC, EC2 instanca i S3 bucket su kreirani kroz assume-role model
- [ ] `terraform apply` prolazi bez gresaka

## Hintovi (opciono)

- Terraform backend za S3 zahteva vise od samog `GetObject` i `PutObject` — istrazi i listanje i lock fajl.
- Backend bucket mora postojati pre `terraform init`; zato se pravi van glavne konfiguracije ili kroz `bootstrap/`.
- Ako su neki IAM resursi vec kreirani rucno, mozes koristiti `terraform import`.
- U produkciji koristi uze policy-je i ogranicen `Resource` scope.

## Korisni linkovi

- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/backend/s3)
- [AWS STS AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
- [Terraform aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [Terraform Import](https://developer.hashicorp.com/terraform/cli/import)

