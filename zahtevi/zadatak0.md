# Zadatak 0: Pocetno podesavanje i pregled projekta

## Cilj

Pripremiti lokalno okruzenje za rad sa Terraform-om i AWS-om. Razumeti strukturu projekta i workflow koji se koristi kroz sve zadatke.

## Preduslovi

- AWS nalog (besplatan Free Tier je dovoljan za vecinu resursa).
- Lokalno instaliran [Terraform CLI](https://developer.hashicorp.com/terraform/install) (verzija >= 1.0).
- Lokalno instaliran [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) (verzija >= 2.0).
- Git za verzionisanje koda.
- Tekst editor ili IDE (preporuka: VS Code sa [HashiCorp Terraform ekstenzijom](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)).

## Struktura projekta

```
terraform-zadaci/
├── *.tf                    # Terraform konfiguracija (IAM, VPC, subnet, EC2, S3)
│   ├── backend.tf          # S3 backend konfiguracija za state
│   ├── iam.tf              # IAM resursi (user, role, policies)
│   ├── locals.tf           # Lokalne promenljive (name_prefix, tagovi)
│   ├── main.tf             # Aplikacioni resursi (VPC, EC2, S3, SG)
│   ├── outputs.tf          # Output vrednosti
│   ├── variables.tf        # Ulazne varijable
│   └── versions.tf         # Provider verzije i konfiguracija
├── docs/                   # Dokumentacija, planovi, checkliste
│   ├── zadatak0/           # Pocetno podesavanje (ovaj fajl)
│   ├── zadatak1/           # IAM setup
│   ├── zadatak2/           # EC2 pristup
│   └── zadatak3/           # Networking i VPC
├── bootstrap/              # Bootstrap konfiguracija za state bucket
└── scripts/                # Pomocni skriptovi
```

## Koraci

### 1. Instaliraj Terraform

```bash
# macOS (Homebrew)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Proveri instalaciju
terraform version
```

Dokumentacija: [Install Terraform](https://developer.hashicorp.com/terraform/install)

### 2. Instaliraj AWS CLI

```bash
# macOS (Homebrew)
brew install awscli

# Proveri instalaciju
aws --version
```

Dokumentacija: [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### 3. Konfiguriši AWS profil

Kreiraj lokalni AWS profil pod imenom `terraform`:

```bash
aws configure --profile terraform
```

Unesi:
- **Access Key ID** — dobijas iz AWS konzole (IAM → Users → terraform-user → Security credentials).
- **Secret Access Key** — prikazuje se samo jednom prilikom kreiranja.
- **Default region** — `us-east-1` (koristi se kroz ceo projekat).
- **Output format** — `json`.

> **Vazno:** Nikada ne upisuj AWS kljuceve u `.tf` fajlove ili git repozitorijum. Koristi AWS profil ili environment varijable.

### 4. Kloniraj repozitorijum

```bash
git clone <repo-url>
cd terraform-zadaci
```

### 5. Inicijalizuj Terraform

```bash
terraform init
```

Ova komanda:
- Preuzima potrebne providere (AWS, TLS).
- Konfigurise S3 backend za state.
- Kreira `.terraform/` direktorijum (ne commit-ovati u git).

### 6. Proveri konfiguraciju

```bash
terraform validate   # sintaksna provera
terraform plan       # pregled promena bez primene
```

## Osnovni Terraform workflow

```bash
terraform init       # jednom, ili kada se menjaju provideri/backend
terraform plan       # pregled sta ce se desiti
terraform apply      # primeni promene
terraform destroy    # obrisi sve resurse (oprezno!)
```

## Pregled zadataka

| Zadatak | Tema | Kljucni koncepti |
|---------|------|------------------|
| **Zadatak 1** | IAM setup | `terraform-user`, `TerraformAdminRole`, S3 backend, assume role |
| **Zadatak 2** | EC2 pristup | SSH key pair, security groups, SSM Session Manager |
| **Zadatak 3** | Networking | VPC, public/private subnet, Internet Gateway, VPC endpoints |

Svaki zadatak se nadovezuje na prethodni — preporucuje se raditi ih redom.

## Saveti

- **State fajl:** Terraform cuva stanje infrastrukture u state fajlu. U ovom projektu se koristi S3 backend — state se cuva u `s3://terraform-state-bucket-uddspring/terraform-zadaci/terraform.tfstate`.
- **Plan pre apply:** Uvek pokreni `terraform plan` pre `terraform apply` da vidis sta ce se promeniti.
- **Destroy oprezno:** `terraform destroy` brise SVE resurse. Koristi samo kada zaista zelis da ocistis okruzenje.
- **Git:** Ne commit-uj `.terraform/`, `*.tfstate`, `*.tfstate.backup`, niti AWS kredencijale.
- **Dokumentacija:** AWS dokumentacija je odlican resurs — linkovi su navedeni u svakom zadatku.

## Korisni linkovi

- [Terraform dokumentacija](https://developer.hashicorp.com/terraform/docs)
- [AWS Provider dokumentacija](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform Best Practices](https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices)

