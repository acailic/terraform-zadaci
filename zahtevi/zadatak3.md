# Zadatak 3: Networking — VPC, Subneti, Internet Gateway, VPC Endpoints

## Cilj

Postaviti kompletnu mreznu infrastrukturu u AWS-u i razumeti razliku izmedju public i private subnet-a. Prebaciti EC2 instancu u private subnet i omoguciti pristup preko VPC PrivateLink endpoint-a.

## Preduslovi

- Zavrseni Zadatak 1 (IAM) i Zadatak 2 (EC2 sa SSM).
- Razumevanje CIDR notacije (npr. `10.0.0.0/16` = 65 536 IP adresa).

## Zahtevi

### 1. VPC (Virtual Private Cloud)

- Kreirati VPC sa CIDR blokom `10.0.0.0/16` (65 536 IP adresa).
- Omoguciti `enable_dns_support` i `enable_dns_hostnames` (potrebno za VPC endpoint-e).

```hcl
resource "aws_vpc" "test" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
```

### 2. Public Subnet + Internet Gateway

- Kreirati public subnet `10.0.1.0/24` (256 IP adresa: 10.0.1.0–10.0.1.255).
- Omoguciti `map_public_ip_on_launch = true` — instance automatski dobijaju public IP.
- Kreirati Internet Gateway i povezati ga sa VPC-om.
- Kreirati route table sa rutom `0.0.0.0/0 → IGW` i povezati ga sa public subnet-om.

> **Kljucno:** Subnet je "public" iskljucivo zato sto ima rutu ka Internet Gateway-u u svom route table-u. Sam subnet ne "zna" da li je public ili private.

**CIDR kalkulator:**

| Mrezni blok | Maska | Broj IP adresa | Opseg |
|-------------|-------|----------------|-------|
| `10.0.0.0/16` | VPC | 65 536 | 10.0.0.0 – 10.0.255.255 |
| `10.0.1.0/24` | Public subnet | 256 | 10.0.1.0 – 10.0.1.255 |
| `10.0.2.0/24` | Private subnet | 256 | 10.0.2.0 – 10.0.2.255 |

> **Tip:** AWS rezervise 5 IP adresa u svakom subnet-u (prvu, poslednju, i 3 za interne servise). Efektivno imate 251 upotrebljivu adresu u /24 subnet-u.

### 3. Private Subnet

- Kreirati private subnet `10.0.2.0/24`.
- `map_public_ip_on_launch = false` — instance nemaju public IP.
- Kreirati **prazan** route table (bez rute ka IGW) i povezati ga sa private subnet-om.

```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.test.id
  # Samo implicitna lokalna ruta: 10.0.0.0/16 → local
  # Nema rute ka IGW — instanca nema internet pristup
}
```

### 4. Prebaciti EC2 u private subnet

- Promeniti `subnet_id` na EC2 instanci sa public na private subnet.
- Ukloniti port 22 iz security grupe (SSH vise nije moguc bez public IP).

> **Vazno:** Promena `subnet_id` forsira **destroy + create** EC2 instance. AWS ne dozvoljava premestanje instance izmedju subnet-a.

### 5. VPC Endpoints za SSM (PrivateLink)

Posto instanca u private subnet-u nema internet, SSM Agent ne moze komunicirati sa AWS servisima. Resenje: **VPC Interface Endpoint-i** koji kreiraju privatnu vezu kroz AWS backbone.

Potrebna su **tri** Interface Endpoint-a:

| Endpoint | Svrha |
|----------|-------|
| `com.amazonaws.<region>.ssm` | SSM API pozivi (registracija, komande) |
| `com.amazonaws.<region>.ssmmessages` | Session Manager websocket kanali |
| `com.amazonaws.<region>.ec2messages` | EC2 Messages polling |

```hcl
resource "aws_vpc_endpoint" "ssm" {
  for_each = toset([
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages",
  ])

  vpc_id              = aws_vpc.test.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true          # KRITICNO
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.vpce.id]
}
```

> **`private_dns_enabled = true`** je najbitniji deo — override-uje javni DNS tako da `ssm.us-east-1.amazonaws.com` resolvuje na privatnu IP adresu ENI-ja u tvom subnet-u umesto na javnu IP. Bez toga, SSM Agent ne moze doci do servisa iz private subnet-a.

### 6. Security grupa za VPC endpoint-e

VPC Interface Endpoint-i kreiraju ENI (Elastic Network Interface) u subnet-u. SSM Agent komunicira na portu **443 (HTTPS)**, pa endpoint mora dozvoliti port 443 iz VPC CIDR-a.

```hcl
resource "aws_security_group" "vpce" {
  vpc_id      = aws_vpc.test.id
  description = "Allow HTTPS from VPC CIDR for SSM VPC endpoints"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
```

### 7. SSH kljuc u Secrets Manager

Umesto cuvanja privatnog kljuca na lokalnom disku, generisati ga u Terraformu (`tls_private_key`) i smestiti u AWS Secrets Manager.

```bash
# Preuzimanje kljuca iz Secrets Manager
aws secretsmanager get-secret-value \
  --secret-id terraform-zadaci-dev-ssh-private-key \
  --profile terraform-admin \
  --query SecretString --output text
```

### 8. Verifikacija

```bash
# SSM pristup instanci u private subnet-u
aws ssm start-session \
  --target $(terraform output -raw test_ec2_instance_id) \
  --profile terraform-admin
```

## Dijagram arhitekture

```
                AWS Cloud
                ┌──────────────────────────────────────────┐
                │  VPC: 10.0.0.0/16                        │
                │                                          │
                │  ┌────────────────┐  ┌────────────────┐  │
                │  │ Public Subnet  │  │ Private Subnet │  │
                │  │ 10.0.1.0/24   │  │ 10.0.2.0/24    │  │
                │  │               │  │                │  │
                │  │ (za buduci    │  │  EC2 instanca  │  │
                │  │  ALB)         │  │  (no public IP)│  │
                │  │               │  │  SSM Agent ────┼──┼── VPC Endpoints
                │  └───────┬───────┘  │                │  │
                │  ┌───────┴───────┐  │  VPC Endpoint  │  │
                │  │ Internet GW   │  │  ENIs (443)    │  │
                │  └───────────────┘  └────────────────┘  │
                └──────────────────────────────────────────┘
```

## Trosak

| Resurs | Cena |
|--------|------|
| 3x VPC Interface Endpoint | ~$21.60/mes ($7.20 svaki) + data transfer |
| Secrets Manager secret | ~$0.40/mes |
| EC2 t3.micro | ~$7.60/mes (on-demand) |
| **Ukupno** | ~$29.60/mes |

## Saveti

- **Public vs Private:** Razlika je iskljucivo u route table-u. Ako ima rutu ka IGW — public. Ako nema — private.
- **VPC Endpoints kostaju:** Tri Interface Endpoint-a su ~$21.60/mes. Alternativa je NAT Gateway (~$32/mes) ili EC2 Instance Connect Endpoint (besplatan).
- **user_data ne radi u private subnet-u:** `yum` zahteva internet. SSM Agent je pre-instaliran, pa SSM radi. Za `yum`, dodati NAT Gateway ili S3 Gateway Endpoint.
- **DNS je kljucan:** `enable_dns_support` i `enable_dns_hostnames` na VPC-u moraju biti `true` da bi `private_dns_enabled` na endpoint-ima radio.
- **for_each vs count:** Koristimo `for_each` sa `toset()` za VPC endpoint-e jer dodavanje/brisanje jednog endpoint-a ne utice na ostale (za razliku od `count`).

## Korisni linkovi

- [AWS VPC dokumentacija](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC Endpoints (PrivateLink)](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
- [Subnet CIDR kalkulator](https://www.subnet-calculator.com/cidr.php)
- [AWS VPC Pricing](https://aws.amazon.com/privatelink/pricing/)
- [Terraform aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)
- [SSM VPC Endpoint zahtevi](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html)

