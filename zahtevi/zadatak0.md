# Zadatak 0: Pocetno podesavanje

## Cilj

Pripremiti lokalno okruzenje za rad sa Terraform-om i AWS-om. Ovaj zadatak je preduslov za sve naredne zadatke.

## Preduslovi

- AWS nalog (Free Tier je dovoljan).
- Git za verzionisanje koda.
- Tekst editor (preporuka: VS Code sa [HashiCorp Terraform ekstenzijom](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)).

## Zahtevi

1. Instalirati [Terraform CLI](https://developer.hashicorp.com/terraform/install) (verzija >= 1.0).
2. Instalirati [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (verzija >= 2.0).
3. Konfigurisati lokalni AWS profil pod imenom `terraform` sa regionom `us-east-1`.
4. Klonirati repozitorijum i pokrenuti `terraform init`.

> **Pravilo:** AWS kljucevi se nikada ne upisuju u `.tf` fajlove niti commit-uju u git. Koristiti AWS profil ili environment varijable.

## Struktura projekta

```
terraform-zadaci/
├── *.tf              # Terraform konfiguracija (IAM, VPC, EC2, S3)
├── docs/             # Dokumentacija i beleske po zadatku
├── bootstrap/        # Bootstrap konfiguracija za state bucket
└── scripts/          # Pomocni skriptovi
```

## Isporuka

- [ ] `terraform version` vraca verziju >= 1.0
- [ ] `aws --version` vraca verziju >= 2.0
- [ ] `aws configure list --profile terraform` prikazuje konfigurisan profil
- [ ] `terraform init` uspesno zavrsava bez gresaka
- [ ] `terraform validate` prolazi

## Pregled zadataka

| Zadatak | Tema | Kljucni koncepti |
|---------|------|------------------|
| **Zadatak 1** | IAM setup | IAM user, IAM role, assume role, S3 backend |
| **Zadatak 2** | EC2 pristup | SSH key pair, security groups, SSM Session Manager |
| **Zadatak 3** | Networking | VPC, subneti, Internet Gateway, VPC endpoints |

Zadaci se nadovezuju redom — svaki pretpostavlja da je prethodni zavrsen.

## Napomene

- `terraform destroy` brise **sve** resurse. Koristiti samo kada zaista zelis da ocistis okruzenje.
- Ne commit-ovati: `.terraform/`, `*.tfstate`, `*.tfstate.backup`, AWS kredencijale.

## Korisni linkovi

- [Terraform dokumentacija](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider dokumentacija](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)

