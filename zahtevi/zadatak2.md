# Zadatak 2: EC2 pristup — SSH key pair, Security Groups, SSM Session Manager

## Cilj

Omoguciti pristup EC2 instanci na dva nacina i razumeti razlike izmedju njih:

1. **SSH** — klasican pristup preko porta 22 sa key pair-om.
2. **SSM Session Manager** — pristup bez otvorenih portova, preko AWS Systems Manager-a.

Na kraju zadatka, SSH se uklanja u korist SSM-a kao bezbednijeg pristupa.

## Preduslovi

- Zavrsen Zadatak 1 (IAM korisnik, rola, VPC i EC2 vec postoje).
- Lokalno instaliran `aws` CLI (za `aws ssm start-session`).
- Instaliran [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) za AWS CLI.

## Zahtevi

### 1. SSH Key Pair

- Generisati SSH kljuc (ED25519 algoritam — moderan i bezbedan).
- Kreirati `aws_key_pair` resurs koji uploada javni kljuc u AWS.
- Dodeliti `key_name` atribut EC2 instanci.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/terraform-zadaci -C "terraform-zadaci"
```

> **Vazno:** Promena `key_name` na postojecoj instanci **forsira zamenu** (destroy + create). EC2 ne moze promeniti key pair bez ponovnog kreiranja.

### 2. Security Group — port 22

- Dodati port 22 (SSH) u listu `ingress_ports` u security grupi.
- Koristiti `dynamic "ingress"` blok za iteraciju kroz listu portova.

```hcl
variable "ingress_ports" {
  default = [80, 22]   # HTTP + SSH
}
```

> **Best practice:** U produkciji, ograniciti `allowed_cidr_blocks` na svoju IP adresu umesto `0.0.0.0/0`:
> ```bash
> terraform apply -var='allowed_cidr_blocks=["<tvoja-ip>/32"]'
> ```

### 3. SSM Session Manager

- Kreirati IAM rolu sa Trust Policy za `ec2.amazonaws.com`.
- Attach-ovati `AmazonSSMManagedInstanceCore` managed policy.
- Kreirati Instance Profile koji omotava rolu.
- Dodeliti Instance Profile EC2 instanci.

**Lanac dozvola:**
```text
EC2 instanca
  └── Instance Profile: ec2-ssm-profile
        └── IAM Role: ec2-ssm-role
              └── Policy: AmazonSSMManagedInstanceCore
```

> **Tip:** SSM Agent je **vec instaliran** na Amazon Linux 2023 AMI-ju. Ne treba ga rucno instalirati.

### 4. Verifikacija SSH pristupa

```bash
ssh -i ~/.ssh/terraform-zadaci ec2-user@$(terraform output -raw test_ec2_public_ip)
```

- `-i` — putanja do privatnog kljuca.
- `ec2-user` — default korisnik na Amazon Linux AMI-ju.

### 5. Verifikacija SSM pristupa

Posto `terraform-user` nema direktne SSM dozvole, potrebno je assume-ovati `TerraformAdminRole`. Dodaj profil u `~/.aws/config`:

```ini
[profile terraform-admin]
source_profile = terraform
role_arn = arn:aws:iam::<account-id>:role/TerraformAdminRole
region = us-east-1
```

```bash
aws ssm start-session --profile terraform-admin --target $(terraform output -raw test_ec2_instance_id)
```

> **Tip:** Ako SSM ne radi odmah, sacekati 2-3 minuta da se SSM Agent registruje.

### 6. Uklanjanje SSH pristupa

Nakon sto SSM radi, ukloniti port 22 iz security grupe:

```hcl
variable "ingress_ports" {
  default = [80]   # samo HTTP, bez SSH
}
```

Ovo je bezbednosni hardening — pristup instanci je iskljucivo preko SSM-a.

## Novi resursi za kreiranje

| Resurs | Tip | Opis |
|--------|-----|------|
| `aws_key_pair.main` | SSH Key Pair | Javni kljuc za EC2 pristup |
| `aws_iam_role.ec2_ssm` | IAM Role | Trust: `ec2.amazonaws.com` |
| `aws_iam_role_policy_attachment.ec2_ssm` | Policy Attachment | `AmazonSSMManagedInstanceCore` |
| `aws_iam_instance_profile.ec2_ssm` | Instance Profile | Omotac za SSM rolu |

## Kljucne razlike SSH vs SSM

| Aspekt | SSH | SSM Session Manager |
|--------|-----|---------------------|
| Port | 22 (inbound) | 443 (outbound) |
| Kljuc | Privatni SSH kljuc | IAM kredencijali |
| Public IP | Potreban | Nije potreban |
| Security group | Mora dozvoliti port 22 | Ne treba nikakvo pravilo |
| Audit log | Lokalni `/var/log/secure` | AWS CloudTrail |

## Saveti

- **Privatni kljuc:** Nikada ne commit-ovati privatni SSH kljuc u git. Dodati `~/.ssh/terraform-zadaci` u `.gitignore`.
- **SSM je preporucan:** Za produkciju koristiti SSM jer ne zahteva otvorene portove i pruza centralizovan audit log.
- **Instance Profile != IAM Role:** EC2 ne moze direktno koristiti IAM rolu — mora kroz Instance Profile. U AWS konzoli ovo je skriveno, ali u Terraformu moras eksplicitno kreirati oba resursa.
- **Stateful firewall:** Security group je stateful — ako dozvolimo inbound na portu 22, odgovor automatski prolazi nazad. Ne treba posebno pravilo za egress.

## Korisni linkovi

- [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- [AmazonSSMManagedInstanceCore Policy](https://docs.aws.amazon.com/aws-managed-policy/latest/reference/AmazonSSMManagedInstanceCore.html)
- [EC2 Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)

