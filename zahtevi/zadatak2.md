# Zadatak 2: EC2 pristup — SSH key pair, Security Groups, SSM Session Manager

## Cilj

Omoguciti pristup EC2 instanci na dva nacina — SSH i SSM Session Manager. Razumeti razlike izmedju njih i zasto se SSM preporucuje za produkciju.

## Preduslovi

- Zavrsen Zadatak 1 (IAM, VPC, EC2 vec postoje).
- Instaliran [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) za AWS CLI.

## Kontekst

EC2 instancama se moze pristupiti na vise nacina. **SSH** je klasican pristup koji zahteva otvoren port i kljuc. **SSM Session Manager** je AWS-ov pristup koji koristi IAM autentikaciju i ne zahteva otvorene portove ni public IP adresu.

## Zahtevi

### 1. Omoguciti SSH pristup

- Generisati SSH key pair (ED25519 algoritam).
- Kreirati Terraform resurs koji uploada javni kljuc u AWS.
- Dodati EC2 instanci referencu na taj key pair.
- Otvoriti port 22 u security grupi za inbound pristup.

### 2. Omoguciti SSM Session Manager

- Kreirati IAM rolu koju EC2 servis moze da assume-uje.
- Dodeliti roli AWS managed policy sa minimalnim dozvolama za SSM Agent.
- Kreirati Instance Profile i dodeliti ga EC2 instanci.

> SSM Agent je vec instaliran na Amazon Linux 2023 AMI-ju. Istrazi sta je **Instance Profile** i zasto EC2 ne moze direktno koristiti IAM rolu.

### 3. Verifikacija

- Demonstrirati uspesnu SSH konekciju na instancu.
- Demonstrirati uspesnu SSM sesiju na instancu.

> `terraform-user` nema direktne SSM dozvole. Razmisli kako da koristis `TerraformAdminRole` iz AWS CLI-ja (hint: AWS profili sa `source_profile` i `role_arn`).

### 4. Uklanjanje SSH pristupa

Nakon sto SSM radi, ukloniti port 22 iz security grupe. Pristup instanci treba da bude iskljucivo preko SSM-a.

## Isporuka

- [ ] SSH key pair postoji u AWS-u i referenciran je na EC2 instanci
- [ ] SSH konekcija na instancu radi
- [ ] EC2 instanca ima Instance Profile sa SSM dozvolama
- [ ] SSM sesija na instancu radi (`aws ssm start-session`)
- [ ] Port 22 je uklonjen iz security grupe (samo SSM pristup ostaje)

## Napomene

- Promena `key_name` na postojecoj instanci forsira **destroy + create** — EC2 ne moze promeniti key pair bez ponovnog kreiranja.
- Port 22 otvoren na `0.0.0.0/0` je prihvatljivo za dev. U produkciji ograniciti na specificnu IP adresu.
- Privatni SSH kljuc se nikada ne commit-uje u git.
- Security group je **stateful** — dozvoljen inbound automatski dozvoljava odgovor nazad.

## Korisni linkovi

- [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- [EC2 Instance Profiles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)
- [EC2 Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)

