# Zadatak 5: RDS baza — MySQL, private subnet, Secrets Manager

## Cilj

Tvoj zadatak je da kreiras MySQL bazu podataka u private subnet-u, povezas je sa EC2 instancom i sacuvas kredencijale u AWS Secrets Manager.

## Preduslovi

- Zavrsen Zadatak 3 (private subnet, EC2 u private subnet-u)
- EC2 instanca sa httpd-om koja moze komunicirati unutar VPC-a

## Tvoj zadatak

1. Kreiraj `aws_db_subnet_group` koji ukljucuje private subnet-e u razlicitim AZ-ama (RDS zahteva minimum 2 AZ-e za subnet group).
2. Kreiraj security grupu za RDS koja dozvoljava MySQL (port 3306) samo od EC2 security grupe.
3. Kreiraj `aws_db_instance` sa:
   - `engine = "mysql"`, `engine_version = "8.0"`
   - `instance_class = "db.t3.micro"` (Free Tier)
   - `allocated_storage = 20` (GB, minimum za Free Tier)
   - `skip_final_snapshot = true` (dev — ne cuva snapshot na destroy)
   - `publicly_accessible = false` (samo unutar VPC-a)
4. Sacuvaj kredencijale (username, password, host, port, connection string) u AWS Secrets Manager kao JSON.
5. Na EC2 instanci testiraj konekciju ka bazi koristeci MySQL klijent.
6. Dodaj output sa RDS endpoint-om i ARN-om Secrets Manager secret-a.

## Isporuka

- [ ] DB Subnet Group postoji sa private subnet-ima u 2 AZ-e
- [ ] RDS security grupa dozvoljava port 3306 samo od EC2 SG (security group chaining)
- [ ] RDS instanca je kreirana sa `db.t3.micro` i MySQL 8.0
- [ ] `publicly_accessible = false`
- [ ] Secrets Manager secret sadrzi JSON sa `username`, `password`, `host`, `port`, `connection_string`
- [ ] EC2 instanca moze da se konektuje na bazu: `mysql -h <rds-endpoint> -u admin -p`
- [ ] `terraform output rds_endpoint` vraca endpoint baze

## Hintovi (opciono)

- Generisi nasumican password u Terraformu: `resource "random_password" "db"` sa `length = 16, special = true`.
- Nikad ne stavljaj password direktno u `.tf` fajl — koristi `random_password` i predaj ga Secrets Manager-u.
- RDS Free Tier: `db.t3.micro`, 20 GB storage, 750 sati mesecno — pazi da ne pokrenues vise instanci jer se Free Tier brzo trosi.
- Security group chaining: RDS SG prima 3306 od EC2 SG ID-ja — `source_security_group_id = aws_security_group.web.id`.
- Da bi MySQL klijent radio na EC2, instaliraj ga u `user_data`: `yum install -y mysql`.
- Connection string format: `mysql://username:password@host:3306/dbname`.
- RDS treba min 2 subneta u razlicitim AZ-ama za subnet group, ali `multi_az = false` moze koristiti samo jednu (za dev).

## Cena (Free Tier)

| Resurs | Cena u Free Tier-u | Ogranicenje |
|--------|-------------------|-------------|
| `db.t3.micro` | Besplatno | 750 sati/mesec (12 meseci) |
| Storage | Besplatno | 20 GB General Purpose SSD |
| Backup storage | Besplatno | Do velicine DB-a |
| Nakon Free Tier-a | ~$0.017/sat | ~$12-13/mesec |

**Vazno:** `terraform destroy` posle testa — RDS instanca trose sate cak i kada je zaustavljena (osim ako je potpuno obrisana).

## Korisni linkovi

- [AWS RDS MySQL dokumentacija](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html)
- [RDS Free Tier](https://aws.amazon.com/rds/free/)
- [Terraform aws_db_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)
- [Terraform aws_db_subnet_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)
- [Terraform random_password](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)
- [Secrets Manager JSON format](https://docs.aws.amazon.com/secretsmanager/latest/userguide/reference_secret_json_structure.html)
