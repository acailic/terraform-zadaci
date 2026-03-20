# terraform-zadaci

Terraform repository with two separate roots:

- `bootstrap/` creates the IAM prerequisites that previously had to be created in the AWS console
- repository root creates the infrastructure by authenticating as `terraform-user` and assuming `TerraformAdminRole`

## Repository structure

```text
bootstrap/          # Bootstrap IAM stack
main.tf             # VPC, subnets, NAT gateway, EC2, S3, VPC endpoints
iam.tf              # IAM role, instance profile, S3 access policy
variables.tf        # Input variables
outputs.tf          # Output values
versions.tf         # Provider config with assume_role
docs/               # Organized guides, tasks, learning materials
```

## Workflow

### 1. Bootstrap IAM

Use direct AWS credentials with IAM permissions. For bootstrap, either pass a
shared AWS profile explicitly or use temporary admin credentials in the
environment:

```bash
terraform -chdir=bootstrap init
terraform -chdir=bootstrap plan -var='aws_profile=admin'
terraform -chdir=bootstrap apply -var='aws_profile=admin'
terraform -chdir=bootstrap output -raw terraform_access_key_id
terraform -chdir=bootstrap output -raw terraform_access_key_secret
aws configure --profile terraform
```

### 2. Main infrastructure

After the local `terraform` AWS profile has a valid access key:

```bash
terraform init
terraform plan
terraform apply
```

The `bootstrap/` stack provisions `terraform-user`, `TerraformAdminRole`,
`TerraformS3BackendPolicy`, and the access key for `terraform-user`. The
repository root provisions the VPC, subnets, EC2, VPC endpoints, Secrets
Manager secret, and the test S3 bucket.

 
## State files

| Stack | State location |
|-------|----------------|
| `bootstrap/` | local state by default |
| repo root | `s3://terraform-state-bucket-uddspring/terraform-zadaci/terraform.tfstate` |

## Authentication

- `bootstrap/` does not assume a role; it must run with direct AWS credentials
  that can create IAM resources.
- The repo root uses the `terraform` shared profile and assumes
  `TerraformAdminRole`.
- Do not commit AWS access keys or secrets into the repository.

## Documentation

- [Bootstrap Stack](bootstrap/README.md) - IAM bootstrap workflow
- [Docs Index](docs/README.md) - Overview of the documentation structure
- [Import Guide](docs/guides/import-guide.md) - Import manually-created IAM resources into the bootstrap stack
- [Provider Versioning Guide](docs/guides/provider-versioning.md) - Terraform provider version management
- [Zadatak 1 - IAM Setup](docs/tasks/zadatak1/README.md) - IAM user, role, and S3 backend configuration
- [Zadatak 2 - EC2 Access](docs/tasks/zadatak2/README.md) - SSH key pair, security group, and SSM Session Manager
- [Learning: NAT, S3, SSH Tunnel](docs/learning/05-nat-s3-ssh-tunnel.md) - NAT gateway, S3 access from EC2, SSH over SSM tunnel

## Current notes



#### 

- [x] dodati internet gateway (`aws_internet_gateway.main`)
- [x] public subnet (`map_public_ip_on_launch = true` + route table 0.0.0.0/0 → IGW)
- [x] srediti varijable — `ami_id` i `instance_type` su sada u `variables.tf`
- [x] CIDR: VPC `10.0.0.0/16` (65 536 IPs), Subnet `10.0.1.0/24` (256 IPs: 10.0.1.0–10.0.1.255)
- [x] EC2 `user_data` — bash script instalira httpd i postavlja index stranicu


- Subnet cidr calculator
###
- [x] inbound 22 za ssh za ec2 instancu (`ingress_ports = [80, 22]`)
- [x] ssh key pair (`aws_key_pair.main` + `key_name` na EC2)
    - [x] private key u AWS Secrets Manager (`aws_secretsmanager_secret.ssh_private_key`)
        - `tls_private_key` generise ED25519 kljuc, cuva se u Secrets Manager
        - retrieve: `aws secretsmanager get-secret-value --secret-id terraform-zadaci-dev-ssh-private-key`
        - info: rotacija kljuceva je bitna — moze se automatizovati sa Lambda
- [x] SSM Session Manager (`aws_iam_instance_profile.ec2_ssm` sa `AmazonSSMManagedInstanceCore`)
    - [x] uklonjen SSH (port 22) iz security grupe — pristup samo preko SSM
    - [x] EC2 prebacen u private subnet (`aws_subnet.private`, 10.0.2.0/24)
    - [x] dodat VPC endpointi (PrivateLink) za SSM: `ssm`, `ssmmessages`, `ec2messages`
    - [x] uklonjena zavisnost od internet gateway-a za EC2
    - [x] SSM pristup: instance profile (ne root) daje kredencijale SSM Agentu
#- connect: `aws ssm start-session --target <instance-id>`

- random suffix fix za secret name
- access key zameniti u aws profile



- [x] NAT gateway (`aws_nat_gateway.main` u public subnetu, `aws_eip.nat`, ruta u private RT)
- [x] SSH pristup preko SSM tunela (kljuc u Secrets Manager, port forwarding kroz SSM)
- [x] S3 pristup sa EC2 instance (`aws_iam_policy.ec2_s3_access` + `aws_vpc_endpoint.s3` gateway)
    - put: `aws s3 cp test.txt s3://bucket/test.txt`
    - get: `aws s3 cp s3://bucket/test.txt ./downloaded.txt`
    - list: `aws s3 ls s3://bucket/`
z6
option a)
- [x] proveriti 443 za ec2 — VPCE SG dozvoljava 443 (SSM endpointi); httpd na EC2 sluša na 80; nema HTTPS listenera na ALB-u (nema SSL cert-a)
- [x] curl localhost:80 — `user_data` instalira httpd i postavlja `/var/www/html/index.html`; ALB health check potvrđuje HTTP 200 na `/index.html`
- [x] ALB ispred EC2 — `aws_lb.main` (internet-facing, application), `aws_security_group.alb` (80 → 0.0.0.0/0), security group chaining (EC2 prihvata 80 samo od ALB SG), target group + HTTP listener; output: `alb_url`
- application firewall (WAF) — nije implementiran, ovo je vise samo pomenuto

option b)
- [x] zakomentarisan ALB (`aws_lb.main`, `aws_security_group.alb`, target group, listener — sve zakomentarisano u main.tf)
- [x] NLB implementiran (`aws_lb.nlb`, internet-facing, network type)
    - NLB radi na Layer 4 (TCP) — prosleđuje TCP konekciju bez inspekcije
    - NLB **nema security group** — propušta originalni client source IP do EC2
    - EC2 SG dozvoljava SSH (22) od `allowed_cidr_blocks` (ne SG chaining kao kod ALB-a)
    - Target Group: TCP port 22, health check = TCP konekcija na port 22
    - Listener: TCP port 22 → forward na SSH target group
    - output: `nlb_dns_name`, `nlb_ssh_command`
    - test: `ssh -i private-key.pem ec2-user@<nlb_dns_name>`

z7
- RDS baza free (MySQL), - EC2 konnectija ka bazi( private subnet)
- sve u secret manager da se cuvaju podaci za konekciju
        --root pass od baze u secret manager( username i root pass). secret manager - moze da cuva podeljen conneciton string(username, password, host, port)  
- MySQL konekcija ka bazi
- Cena za rds


- Containers registry and service


-----
- da iskljucim asi

usput predlozi:

-- permisije: 600 vs 644 owner,read/write, owner, others
- VPC,

-- linux komande, permisije, interfjesiji,permisjije 
- CNAME, A record, DNS, Route53