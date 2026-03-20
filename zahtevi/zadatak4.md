# Zadatak 4: Load Balancing — ALB, Target Groups, Health Checks

## Cilj

Tvoj zadatak je da postavis Application Load Balancer (ALB) ispred EC2 instance u private subnet-u, tako da korisnici pristupaju web serveru iskljucivo preko ALB-a.

## Preduslovi

- Zavrsen Zadatak 3
- EC2 instanca u private subnet-u sa httpd servisom na portu 80
- Postojeci public subnet sa Internet Gateway-om

## Tvoj zadatak

1. Kreiraj drugi public subnet u drugoj Availability Zone (ALB zahteva minimum 2 AZ-a).
2. Kreiraj ALB security grupu koja dozvoljava HTTP (port 80) sa interneta.
3. Kreiraj internet-facing Application Load Balancer u oba public subnet-a.
4. Kreiraj Target Group sa HTTP health check-om na `/index.html`.
5. Registruj EC2 instancu u Target Group.
6. Kreiraj HTTP listener (port 80) koji prosledjuje zahteve na Target Group.
7. Primeni security group chaining — EC2 security grupa treba da dozvoljava port 80 samo od ALB security grupe (ne od `0.0.0.0/0`).
8. (Bonus) Uporedi ALB i NLB — objasni razlike u Layer 4 vs Layer 7, rutiranju i security group podrski.

## Isporuka

- [ ] Drugi public subnet postoji u drugoj AZ (npr. `us-east-1b`)
- [ ] ALB je `internet-facing` i ima svoju security grupu (port 80)
- [ ] Target Group ima health check na `/index.html` sa status kodom 200
- [ ] EC2 instanca je registrovana u Target Group i prolazi health check
- [ ] HTTP listener na portu 80 prosledjuje zahteve na Target Group
- [ ] EC2 prima HTTP saobracaj **samo** od ALB-a (security group chaining)
- [ ] `curl http://<ALB-DNS-NAME>` vraca "Hello from ..." odgovor
- [ ] ALB DNS ime je izlozeno kao Terraform output

## Hintovi (opciono)

- ALB zahteva minimum 2 subneta u razlicitim AZ-ama zbog high availability — AWS postavlja po jedan ALB node u svaki subnet.
- NLB nema security grupu i propusta client IP direktno do EC2. ALB ima SG i zamenjuje source IP svojim internim IP-jem.
- Security group chaining: umesto `cidr_blocks`, koristi `security_groups = [aws_security_group.alb.id]` u EC2 ingress pravilu.
- Health check `healthy_threshold = 2` znaci da su potrebna 2 uspesna odgovora da bi target bio "healthy".

## Korisni linkovi

- [AWS ALB dokumentacija](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
- [ALB vs NLB](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html#application-load-balancer-overview)
- [Terraform aws_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb)
- [Terraform aws_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group)
- [Terraform aws_lb_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener)
