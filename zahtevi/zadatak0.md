# Zadatak 0: Pocetno podesavanje

## Cilj

Tvoj zadatak je da pripremis lokalno okruzenje za rad sa Terraform-om i AWS-om. Ovo je pocetna tacka za sve naredne zadatke.

## Preduslovi

- AWS nalog
- Git
- Editor ili IDE

## Tvoj zadatak

1. Instaliraj [Terraform CLI](https://developer.hashicorp.com/terraform/install) (verzija `>= 1.0`).
2. Instaliraj [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (verzija `>= 2.0`).
3. Konfigurisi lokalni AWS profil pod imenom `terraform` sa regionom `us-east-1`.
4. Konfigurisi `.gitignore` za Terraform projekte (`.terraform/`, `*.tfstate`, `*.tfstate.backup`).
5. Definiši ogranicenja verzija za Terraform i provajdere u `versions.tf`.
6. Preuzmi projekat i pokreni `terraform init`.
7. Upoznaj se sa osnovnom strukturom projekta: Terraform fajlovi u root-u, `bootstrap/` za backend bootstrap i `zahtevi/` za zadatke.

## Isporuka

- [ ] `terraform version` prikazuje odgovarajucu verziju
- [ ] `aws --version` prikazuje odgovarajucu verziju
- [ ] AWS profil `terraform` je konfigurisan
- [ ] `.gitignore` pokriva Terraform artefakte (`.terraform/`, `*.tfstate`, `*.tfstate.backup`)
- [ ] `versions.tf` definise `required_version` i `required_providers`
- [ ] `terraform init` prolazi bez gresaka
- [ ] `terraform validate` prolazi bez gresaka

## Hintovi (opciono)

- AWS kljuceve nemoj upisivati u `.tf` fajlove niti commit-ovati u git.
- Ne commit-uj `.terraform/`, `*.tfstate` i `*.tfstate.backup`.
- `terraform destroy` brise sve resurse iz state-a — koristi ga oprezno.

## Korisni linkovi

- [Terraform dokumentacija](https://developer.hashicorp.com/terraform/docs)
- [AWS CLI dokumentacija](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- [AWS Provider dokumentacija](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

