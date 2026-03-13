# Zadatak 3: Networking — VPC, Subneti, Internet Gateway, VPC Endpoints

## Cilj

Postaviti mreznu infrastrukturu sa public i private subnet-om. Prebaciti EC2 instancu u private subnet bez internet pristupa i omoguciti SSM pristup kroz VPC endpoint-e.

## Preduslovi

- Zavrseni Zadatak 1 (IAM) i Zadatak 2 (EC2 sa SSM u public subnet-u).
- Razumevanje CIDR notacije.

## Kontekst

U produkciji, compute resursi (EC2) se stavljaju u **private subnet** bez direktnog internet pristupa. Komunikacija sa AWS servisima (npr. SSM) se ostvaruje kroz **VPC endpoint-e** (PrivateLink) — saobracaj nikad ne napusta AWS mrezu.

Koristiti sledece CIDR blokove:

| Mrezni blok | Namena | IP adresa |
|-------------|--------|-----------|
| `10.0.0.0/16` | VPC | 65 536 |
| `10.0.1.0/24` | Public subnet | 256 |
| `10.0.2.0/24` | Private subnet | 256 |

## Zahtevi

### 1. VPC

Kreirati VPC sa CIDR blokom `10.0.0.0/16`. DNS podrska mora biti omogucena (potrebna za VPC endpoint-e).

### 2. Public subnet sa Internet Gateway-om

- Kreirati subnet `10.0.1.0/24` u kome instance automatski dobijaju public IP.
- Kreirati Internet Gateway i povezati ga sa VPC-om.
- Kreirati route table sa default rutom (`0.0.0.0/0`) ka IGW-u i asocirati ga sa subnet-om.

> Istrazi: sta subnet cini "public"-om? (hint: nije sam subnet, vec nesto drugo)

### 3. Private subnet

- Kreirati subnet `10.0.2.0/24` bez public IP-ja.
- Kreirati route table **bez** rute ka internetu i asocirati ga sa subnet-om.

### 4. Prebaciti EC2 u private subnet

- Promeniti subnet EC2 instance sa public na private.
- Ukloniti port 22 iz security grupe (SSH nije moguc bez public IP).

### 5. VPC endpoint-i za SSM

Instanca u private subnet-u nema internet — SSM Agent ne moze komunicirati sa AWS servisima. Potrebno je kreirati VPC Interface Endpoint-e koji omogucavaju privatnu komunikaciju.

Istrazi koje **tri** endpoint servisa su potrebna da bi SSM Session Manager radio iz private subnet-a.

> Hint: svaki endpoint treba svoju security grupu koja dozvoljava HTTPS (443) iz VPC CIDR-a. Obrati paznju na DNS konfiguraciju endpoint-a.

### 6. SSH kljuc u Secrets Manager

Umesto cuvanja privatnog SSH kljuca na lokalnom disku, generisati ga u Terraformu i smestiti u AWS Secrets Manager.

> Istrazi `tls_private_key` resurs iz `hashicorp/tls` providera.

## Isporuka

- [ ] VPC postoji sa CIDR `10.0.0.0/16` i DNS podrskom
- [ ] Public subnet (`10.0.1.0/24`) ima Internet Gateway i route table sa default rutom
- [ ] Private subnet (`10.0.2.0/24`) ima route table bez internet pristupa
- [ ] EC2 instanca je u private subnet-u, bez public IP adrese
- [ ] Port 22 je uklonjen iz security grupe
- [ ] VPC endpoint-i omogucavaju SSM pristup iz private subnet-a
- [ ] `aws ssm start-session` uspesno otvara sesiju na instanci
- [ ] SSH privatni kljuc je u AWS Secrets Manager-u

## Ciljna arhitektura

```
                ┌──────────────────────────────────────────┐
                │  VPC: 10.0.0.0/16                        │
                │                                          │
                │  ┌────────────────┐  ┌────────────────┐  │
                │  │ Public Subnet  │  │ Private Subnet │  │
                │  │ 10.0.1.0/24   │  │ 10.0.2.0/24    │  │
                │  │               │  │                │  │
                │  │ (za buduci    │  │  EC2 instanca  │  │
                │  │  ALB)         │  │  (no public IP)│  │
                │  │               │  │       │        │  │
                │  └───────┬───────┘  │  VPC Endpoints │  │
                │  ┌───────┴───────┐  │  (PrivateLink)  │  │
                │  │ Internet GW   │  │       │        │  │
                │  └───────────────┘  └───────┼────────┘  │
                └─────────────────────────────┼───────────┘
                                              │
                                      AWS backbone
                                              │
                                      AWS SSM servisi
```

## Napomene

- Promena `subnet_id` na EC2 instanci forsira **destroy + create**. AWS ne dozvoljava premestanje instance izmedju subnet-a.
- `user_data` skripte koje koriste `yum` nece raditi u private subnet-u jer nema internet pristupa. SSM Agent je pre-instaliran, pa SSM i dalje radi.
- VPC Interface Endpoint-i kostaju ~$7.20/mes svaki. Tri endpoint-a = ~$21.60/mes.
- AWS rezervise 5 IP adresa u svakom subnet-u — efektivno imate 251 upotrebljivu adresu u /24.

## Korisni linkovi

- [AWS VPC dokumentacija](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC Endpoints (PrivateLink)](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
- [SSM VPC Endpoint zahtevi](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html)
- [Subnet CIDR kalkulator](https://www.subnet-calculator.com/cidr.php)
- [Terraform aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)
- [Terraform tls_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key)

