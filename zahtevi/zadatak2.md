# Zadatak 2: EC2 pristup — SSH key pair, Security Groups, SSM Session Manager

## Cilj

Tvoj zadatak je da uvedes dva nacina pristupa EC2 instanci — SSH i SSM Session Manager — a zatim da kao finalno stanje zadrzis samo SSM pristup.

## Preduslovi

- Zavrsen Zadatak 1
- Instaliran [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## Tvoj zadatak

1. Privremeno omoguci SSH pristup EC2 instanci.
2. Generisi SSH key pair i povezi ga sa EC2 instancom.
3. Otvori port `22` u security grupi kako bi SSH radio.
4. Omoguci SSM Session Manager preko IAM role i Instance Profile-a na instanci.
5. Potvrdi da i SSH i SSM pristup rade.
6. Nakon toga ukloni SSH pristup tako da finalno stanje bude pristup samo preko SSM-a.

## Isporuka

- [ ] SSH key pair postoji u AWS-u i povezan je sa EC2 instancom
- [ ] Tokom izrade uspesno je demonstrirana SSH konekcija na instancu
- [ ] EC2 instanca ima Instance Profile sa dozvolama za SSM
- [ ] Uspesno je demonstrirana SSM sesija na instancu
- [ ] Finalno stanje: port `22` je uklonjen iz security grupe
- [ ] Finalno stanje: pristup instanci radi samo preko SSM-a

## Hintovi (opciono)

- SSM Agent je vec instaliran na Amazon Linux 2023 AMI-ju.
- EC2 ne koristi IAM rolu direktno, vec preko **Instance Profile** resursa.
- `terraform-user` nema direktne SSM dozvole; razmisli kako AWS CLI moze da koristi `TerraformAdminRole`.
- Promena `key_name` na postojecoj instanci moze zahtevati ponovno kreiranje instance.

## Korisni linkovi

- [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
- [AWS SSM Session Manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)
- [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- [EC2 Instance Profiles](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)
- [EC2 Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)

