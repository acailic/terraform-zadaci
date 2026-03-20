# Zadatak 6: Containers — ECR registry i ECS servis

## Cilj

Tvoj zadatak je da kontejnerizujes web aplikaciju, pushujes Docker image u Amazon ECR (Elastic Container Registry) i pokraces ga kao ECS servis (Elastic Container Service) u private subnet-u.

## Preduslovi

- Zavrsen Zadatak 4 (ALB ispred servisa)
- Docker instaliran lokalno
- AWS CLI konfigurisan sa `terraform` profilom

## Tvoj zadatak

1. Kreiraj `aws_ecr_repository` za cuvanje Docker image-a.
2. Konfigurisi ECR lifecycle policy — npr. cuva max 5 image-a, brise starije.
3. Napravi jednostavan Dockerfile (npr. nginx ili custom httpd) i pushuj image u ECR:
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ecr-url>
   docker build -t myapp .
   docker tag myapp:latest <ecr-url>/myapp:latest
   docker push <ecr-url>/myapp:latest
   ```
4. Kreiraj `aws_ecs_cluster`.
5. Kreiraj `aws_ecs_task_definition` sa Fargate launch type-om:
   - `cpu = 256`, `memory = 512` (najmanji Fargate task)
   - Container image iz ECR-a
   - Port mapping 80 → 80
6. Kreiraj `aws_ecs_service` koji pokrace 2 zadatka (replika) u private subnet-u.
7. Povezi ECS servis sa postojecim ALB Target Group-om.
8. Dodaj IAM role za ECS task execution (`ecsTaskExecutionRole`) da bi Fargate mogao da povuce image iz ECR-a.

## Isporuka

- [ ] ECR repository postoji i image je uspesno pushnut
- [ ] ECR lifecycle policy ogranicava broj sacuvanih image-a
- [ ] ECS cluster je kreiran
- [ ] Task Definition koristi Fargate sa ECR image-om
- [ ] ECS Service pokrace 2 zadatka u private subnet-u
- [ ] ECS servis je registrovan u ALB Target Group-om
- [ ] `curl http://<ALB-DNS>` vraca odgovor iz kontejnera
- [ ] `ecsTaskExecutionRole` ima pristup ECR-u i CloudWatch Logs-u

## Hintovi (opciono)

- Fargate je "serverless" za kontejnere — ne upravljas EC2 instancama, placas samo CPU i memoriju dok task radi.
- `ecsTaskExecutionRole` je razlicita od task role: execution role daje Fargate-u pravo da povuce image i salje logove; task role daje dozvole aplikaciji unutar kontejnera.
- Za logs: dodaj `awslogs` log driver u task definition i kreiraj `aws_cloudwatch_log_group`.
- `aws_ecr_repository` ima `force_delete = true` — korisno za dev da `terraform destroy` ocisti i image-e.
- Fargate tasks u private subnet-u trebaju VPC endpoint za ECR (`com.amazonaws.region.ecr.api`, `com.amazonaws.region.ecr.dkr`) ili NAT Gateway za pullovanje image-a.
- Cena Fargate: `256 CPU units` = 0.25 vCPU × $0.04048/vCPU-sat + 0.5 GB × $0.004445/GB-sat ≈ $0.01/sat po tasku.

## Razlika: ECS vs EC2

| | EC2 (Zadatak 3) | ECS Fargate |
|--|-----------------|-------------|
| Upravljanje | Ti menadzujes OS, patching | AWS menadzuje infrastrukturu |
| Skaliranje | Auto Scaling Group | ECS Service desired count |
| Pakovanje | AMI + user_data bash | Docker image |
| Pokretanje | Minuti (boot time) | Sekunde |
| Cena | Po instanci (uptime) | Po CPU/memoriji (uptime taska) |

## Korisni linkovi

- [Amazon ECR dokumentacija](https://docs.aws.amazon.com/AmazonECR/latest/userguide/what-is-ecr.html)
- [Amazon ECS sa Fargate](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/AWS_Fargate.html)
- [Terraform aws_ecr_repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository)
- [Terraform aws_ecs_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster)
- [Terraform aws_ecs_task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition)
- [Terraform aws_ecs_service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service)
- [ECS Task Execution Role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_execution_IAM_role.html)
