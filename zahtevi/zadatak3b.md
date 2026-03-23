# Zadatak 3b: NAT Gateway, S3 pristup sa EC2, SSH tunel

## Cilj

Tvoj zadatak je da omogucis EC2 instanci u private subnet-u izlaz na internet preko NAT Gateway-a, direktan pristup S3 bucket-u preko VPC Gateway Endpoint-a, i SSH pristup preko SSM tunela.

## Preduslovi

- Zavrsen Zadatak 3 (EC2 u private subnet-u, SSM pristup)
- Postojeci public subnet sa Internet Gateway-om

## Tvoj zadatak

1. Kreiraj Elastic IP i NAT Gateway u public subnet-u.
2. Dodaj rutu `0.0.0.0/0 → NAT Gateway` u private route table — EC2 sada ima izlaz na internet.
3. Kreiraj S3 Gateway VPC Endpoint (besplatan) povezan sa private route table-om — S3 saobracaj ide preko AWS backbone-a, ne preko NAT-a.
4. Dodaj IAM politiku koja dozvoljava EC2 instanci `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` i `s3:ListBucket` na test bucket-u.
5. Testiraj S3 pristup sa EC2 instance:
   - `aws s3 cp test.txt s3://<bucket>/test.txt`
   - `aws s3 cp s3://<bucket>/test.txt ./downloaded.txt`
   - `aws s3 ls s3://<bucket>/`
6. Testiraj SSH pristup preko SSM tunela:
   - Preuzmi privatni kljuc iz Secrets Manager-a
   - Otvori SSM tunel: `aws ssm start-session --target <instance-id> --document-name AWS-StartPortForwardingSession --parameters portNumber=22,localPortNumber=2222`
   - Konektuj se: `ssh -i key.pem -p 2222 ec2-user@localhost`

## Isporuka

- [ ] NAT Gateway postoji u public subnet-u sa Elastic IP-jem
- [ ] Private route table ima rutu `0.0.0.0/0 → NAT Gateway`
- [ ] EC2 instanca moze da pristupi internetu (npr. `yum update` radi)
- [ ] S3 Gateway Endpoint postoji i povezan je sa private route table-om
- [ ] EC2 IAM politika dozvoljava S3 pristup na test bucket-u
- [ ] `aws s3 cp` upload i download rade sa EC2 instance
- [ ] SSH preko SSM tunela radi (port forwarding na port 22)

## Hintovi (opciono)

- NAT Gateway se placa po satu i po GB saobracaja — za dev okruzenje obrati paznju na troskove.
- S3 Gateway Endpoint je besplatan i brzi od NAT-a za S3 saobracaj.
- SSM tunel zahteva Session Manager plugin instaliran lokalno.
- NAT Gateway MORA biti u public subnet-u (sa rutom ka IGW-u).

## Korisni linkovi

- [AWS NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [VPC Gateway Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints-s3.html)
- [SSM Port Forwarding](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html)
- [Terraform aws_nat_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway)
- [Terraform aws_vpc_endpoint](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint)
