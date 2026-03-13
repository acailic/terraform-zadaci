# Zadatak 3: Networking — VPC, subneti, Internet Gateway, VPC endpoint-i

## Cilj

Tvoj zadatak je da izgradis mreznu arhitekturu u kojoj je EC2 instanca smestena u private subnet i dostupna samo preko SSM-a.

## Preduslovi

- Zavrsen Zadatak 2
- Osnovno razumevanje CIDR notacije

## Tvoj zadatak

1. Kreiraj VPC sa CIDR blokom `10.0.0.0/16` i omogucenom DNS podrskom.
2. Kreiraj public subnet `10.0.1.0/24` sa Internet Gateway-om i route table-om koji ima izlaz na internet.
3. Kreiraj private subnet `10.0.2.0/24` sa sopstvenim route table-om bez ruta ka internetu.
4. Prebaci EC2 instancu u private subnet i ukloni potrebu za SSH pristupom.
5. Dodaj `tls` provider u `versions.tf`.
6. Dodaj VPC Interface Endpoint-e potrebne da SSM radi iz private subnet-a.
7. Dodaj security grupu za endpoint-e koja dozvoljava HTTPS saobracaj iz VPC-a.
8. Kao bezbednosni zahtev, generisi SSH kljuc u Terraformu i sacuvaj privatni kljuc u AWS Secrets Manager-u.

## Isporuka

- [ ] VPC postoji sa CIDR `10.0.0.0/16` i DNS podrskom
- [ ] Public subnet `10.0.1.0/24` ima Internet Gateway i odgovarajuci route table
- [ ] Private subnet `10.0.2.0/24` ima sopstveni route table bez ruta ka internetu
- [ ] EC2 instanca je u private subnet-u i nema public IP adresu
- [ ] Port `22` je uklonjen iz security grupe
- [ ] SSM radi iz private subnet-a preko VPC endpoint-a
- [ ] `aws ssm start-session` uspesno otvara sesiju na instanci
- [ ] SSH privatni kljuc je sacuvan u AWS Secrets Manager-u

## Hintovi (opciono)

- Subnet je public ili private zbog route table-a, ne zbog samog subnet resursa.
- Za SSM iz private subnet-a potrebno je vise od jednog endpoint-a; istrazi koje servise koristi Session Manager.
- Obrati paznju na DNS podesavanja VPC endpoint-a.
- Promena subnet-a na EC2 instanci obicno zahteva ponovno kreiranje instance.

## Korisni linkovi

- [AWS VPC dokumentacija](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html)
- [VPC Endpoints (PrivateLink)](https://docs.aws.amazon.com/vpc/latest/privatelink/what-is-privatelink.html)
- [SSM VPC Endpoint zahtevi](https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html)
- [Terraform aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)
- [Terraform tls_private_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key)

