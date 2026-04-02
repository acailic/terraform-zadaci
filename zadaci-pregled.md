# Terraform zadaci

Ovaj dokument je namenjen novom praktikantu koji postepeno prolazi kroz AWS i Terraform osnove na jednom realnom primeru. Zadaci se rade redom. Nemoj da preskačeš korake, jer svaki sledeći zadatak polazi od toga da je prethodni već završen.

Cilj nije samo da infrastruktura proradi, nego da razumeš zašto je nešto urađeno baš tako. Na kraju ovog niza treba da imaš kompletan AWS setup: VPC, privatne EC2 instance, pristup preko SSM-a, load balancer, RDS bazu, HTTPS i custom domen.

Za svaki zadatak gledaj tri stvari:

- šta treba da napraviš
- zašto se to radi
- kako proveravaš da je zadatak stvarno gotov

---

## Zadatak 1: IAM setup sa S3 backend-om

### Cilj

Postavi osnovu za ceo projekat tako da Terraform radi bez direktnog admin korisnika.

### Šta treba da uradiš

- Napravi IAM korisnika `terraform-user`.
- Ograniči tog korisnika tako da može samo:
- da čita i piše Terraform state u S3 bucket
- da uradi assume role na `TerraformAdminRole`
- Napravi rolu `TerraformAdminRole` koja ima dovoljno dozvola da Terraform može da kreira infrastrukturu.
- S3 bucket za Terraform state drži van glavnog Terraform koda.
- Uključi versioning i enkripciju na state bucket-u.

### Na šta obrati pažnju

`terraform-user` ne treba da bude admin. Ideja je da korisnik ima minimalna prava, a da Terraform po potrebi preuzima rolu sa jačim dozvolama.

### Kako proveravaš da je gotovo

- `terraform apply` prolazi uspešno.
- Terraform koristi assume role, a ne direktna admin prava korisnika.
- State se čuva u S3 bucket-u, a ne lokalno.

---

## Zadatak 2: SSH key pair, port 22, SSM Session Manager

### Cilj

Omogući pristup EC2 instanci na dva načina i razumi razliku između njih.

### Šta treba da uradiš

- Generiši SSH ključ pomoću `ssh-keygen`.
- Dodaj javni ključ u AWS kao `aws_key_pair`.
- Otvori port 22 u security grupi za EC2.
- Podesi SSM Session Manager za istu instancu.
- Dodaj IAM Instance Profile sa policy-jem `AmazonSSMManagedInstanceCore`.

### Na šta obrati pažnju

Ovo je namerno prelazni korak. SSH radi, ali nije najbolji dugoročni pristup. SSM je bezbedniji jer ne traži otvoren port. Takođe, EC2 ne koristi IAM rolu direktno, već kroz Instance Profile.

### Kako proveravaš da je gotovo

- Možeš da se povežeš na instancu preko SSH-a.
- Možeš da otvoriš shell preko SSM Session Manager-a.
- Razumeš zašto security grupa ne traži posebno pravilo za povratni saobraćaj.

---

## Zadatak 3: Private subnet, VPC endpointi, Secrets Manager

### Cilj

Premesti EC2 instancu u privatnu mrežu i zadrži upravljanje bez javnog pristupa.

### Šta treba da uradiš

- Premesti EC2 iz public u private subnet.
- Ukloni javnu IP adresu sa instance.
- Ukloni port 22 iz security grupe.
- Napravi VPC Interface Endpoint-e za:
- `ssm`
- `ssmmessages`
- `ec2messages`
- Uključi `private_dns_enabled = true`.
- Generiši SSH ključ preko Terraform resursa `tls_private_key`.
- Sačuvaj privatni ključ u Secrets Manager.

### Na šta obrati pažnju

Instanca u private subnetu nema izlaz na internet. Ako želiš da SSM i dalje radi, AWS servisi moraju da budu dostupni privatno kroz VPC endpoint-e. Takođe, promena `subnet_id` ili `key_name` na EC2 često znači recreation instance.

### Kako proveravaš da je gotovo

- Instanca više nije javno dostupna.
- Port 22 nije otvoren.
- SSM i dalje radi.
- Privatni ključ nije na lokalnom disku, već u Secrets Manager-u.

---

## Zadatak 4: NAT Gateway + S3 pristup + SSH tunel

### Cilj

Omogući privatnoj instanci izlaz na internet bez otvaranja inbound pristupa.

### Šta treba da uradiš

- Napravi NAT Gateway u public subnetu.
- Dodeli mu Elastic IP.
- U private route table dodaj rutu `0.0.0.0/0` ka NAT Gateway-u.
- Napravi S3 Gateway VPC Endpoint.
- Podesi SSH preko SSM tunela kroz `ProxyCommand` u `~/.ssh/config`.

### Na šta obrati pažnju

NAT daje samo izlazni pristup. To znači da instanca može da radi update, instalaciju paketa i pristup spoljnim servisima, ali i dalje niko spolja ne može direktno da joj pristupi. S3 pristup ne treba da ide preko NAT-a ako može preko gateway endpoint-a.

### Kako proveravaš da je gotovo

- Instanca može da pristupi internetu iz private subnet-a.
- Može da pristupi S3 bucket-u bez javnog izlaza kroz NAT za S3 saobraćaj.
- SSH radi preko SSM tunela bez otvorenog porta 22.

---

## Zadatak 5: RDS MySQL baza + Secrets Manager

### Cilj

Dodaj privatnu MySQL bazu i bezbedno prosledi kredencijale aplikaciji.

### Šta treba da uradiš

- Napravi MySQL 8.0 RDS instancu.
- Postavi `publicly_accessible = false`.
- Napravi DB Subnet Group sa najmanje dva subneta u različitim AZ-ama.
- Napravi security grupu za RDS koja dozvoljava port 3306 samo od EC2 security grupe.
- Generiši lozinku kroz `random_password`.
- Sačuvaj podatke za konekciju u Secrets Manager kao JSON.
- Daj EC2 instanci IAM dozvolu da čita taj secret.

### Na šta obrati pažnju

RDS ne treba da bude otvoren prema internetu. Takođe, ovde je bolje koristiti security group chaining nego CIDR blokove, jer je preciznije i manje je krhko kad se IP adrese menjaju.

### Kako proveravaš da je gotovo

- RDS instanca postoji i nije javno dostupna.
- EC2 može da dođe do baze na portu 3306.
- Kredencijali nisu upisani ručno u kod ili `.tf` fajlove.
- Secret u Secrets Manager-u sadrži sve što aplikaciji treba za konekciju.

---

## Zadatak 6: ALB i NLB - dva pristupa load balancing-u

### Cilj

Razumi kada se koristi ALB, a kada NLB.

### Šta treba da uradiš

- Napravi ALB za HTTP saobraćaj.
- Dodeli mu security grupu.
- Podesi target group i health check.
- Dozvoli EC2 instanci HTTP samo od ALB security grupe.
- Napravi i NLB kao alternativni pristup.
- Poveži NLB sa odgovarajućim target group-om.

### Na šta obrati pažnju

ALB radi na Layer 7 i dobar je za web saobraćaj, URL routing, SSL terminaciju i kasnije WAF. NLB radi na Layer 4, nema security grupu i zadržava originalni client IP. Ovaj zadatak je koristan da ne mešaš ta dva servisa ubuduće.

### Kako proveravaš da je gotovo

- ALB može da prosledi HTTP zahteve ka EC2.
- NLB radi kao odvojen primer za TCP prosleđivanje.
- Jasno ti je zašto backend pravila nisu ista za ALB i NLB.

---

## Zadatak 7: RDS + PHP Web App + NLB HTTP listener

### Cilj

Poveži bazu i aplikaciju tako da u browseru vidiš podatke iz MySQL baze.

### Šta treba da uradiš

- Na EC2 instanci instaliraj PHP i potrebne MySQL pakete.
- Napravi `db.php` stranicu koja čita podatke iz baze.
- U `user_data` skripti preuzmi kredencijale iz Secrets Manager-a.
- Sačuvaj ih lokalno u JSON fajl i `.my.cnf`.
- Dodaj retry logiku u `user_data` da sačeka Secrets Manager ako nije odmah dostupan.
- Podesi NLB listener na portu 80 ka EC2 portu 80.

### Na šta obrati pažnju

Najčešći problem u ovom koraku nije PHP, nego redosled podizanja resursa. `user_data` može da krene pre nego što NAT ili endpointi budu spremni, pa retry ovde nije luksuz nego potreba. Obrati pažnju i na permisije fajlova sa kredencijalima.

### Kako proveravaš da je gotovo

- Otvaraš `http://<nlb_dns>/db.php`.
- Stranica uspešno čita podatke iz baze.
- Kredencijali nisu ručno kopirani na instancu.
- Fajlovi sa kredencijalima imaju ograničene permisije.

---

## Zadatak 8: ALB sa 2 EC2 instance (High Availability)

### Cilj

Ukloni single point of failure na aplikativnom sloju.

### Šta treba da uradiš

- Umesto jedne instance podigni dve EC2 instance.
- Smesti ih u dve različite Availability Zone.
- Postavi ih iza jednog ALB-a.
- Uvedi feature flagove kao što su `create_alb` i `create_rds`.
- Dodaj `ec2_instance_count` da broj instanci može da se kontroliše kroz Terraform varijable.
- Ukloni NLB iz glavnog HTTP toka.

### Na šta obrati pažnju

Ovde prelaziš sa "radi na jednoj mašini" na "radi i kad jedna mašina padne". To je važna razlika. Takođe, feature flagovi su bitni jer omogućavaju da tokom razvoja pališ samo delove infrastrukture koji ti trebaju.

### Kako proveravaš da je gotovo

- ALB vidi obe instance kao healthy.
- Aplikacija je dostupna preko ALB-a.
- Infrastruktura može da se pali i gasi kroz varijable bez ručnog komentarisanja pola koda.

---

## Zadatak 9: ALB HA failover testiranje

### Cilj

Proveri da li high availability stvarno radi, a ne samo da lepo izgleda u Terraform plan-u.

### Šta treba da uradiš

- Potvrdi da obe instance odgovaraju normalno.
- Ugasi jednu instancu i proveri da li ALB nastavlja da služi saobraćaj preko druge.
- Ugasi i drugu instancu i proveri da li ALB vraća `503 Service Unavailable`.
- Ponovo podigni instance i prati kako se vraćaju u healthy stanje.

### Na šta obrati pažnju

Failover nije trenutan. Health check ima svoj interval i broj pokušaja, pa treba vremena da ALB proglasi target unhealthy ili healthy. Bitno je da to vidiš u praksi, jer se tu najlakše pogrešno proceni ponašanje sistema.

### Kako proveravaš da je gotovo

- Sa jednom ugašenom instancom aplikacija i dalje radi.
- Sa obe ugašene instance dobijaš očekivan `503`.
- Kada ih vratiš, ALB ih ponovo registruje kao healthy target-e.

---

## Zadatak 10: HTTPS/SSL sa ACM certifikatom i Route 53

### Cilj

Završi infrastrukturu tako da aplikacija radi preko pravog domena i HTTPS-a.

### Šta treba da uradiš

- Napravi Route 53 hosted zonu za domen.
- Dodaj A alias record ka ALB-u.
- Napravi ACM sertifikat sa DNS validacijom.
- Dodaj HTTPS listener na ALB port 443.
- Pretvori HTTP listener na portu 80 u redirect ka HTTPS-u.

### Na šta obrati pažnju

SSL terminaciju radi ALB, ne EC2 instanca. To znači da sertifikat držiš na jednom mestu i backend ne mora da se bavi TLS-om. Ako koristiš `.dev` domen, browser će insistirati na HTTPS-u zbog HSTS pravila.

### Kako proveravaš da je gotovo

- `https://<domen>` radi sa validnim sertifikatom.
- `http://<domen>` radi redirect na HTTPS.
- Domen pokazuje na ALB preko Route 53 zapisa.

---

## Sledeći korak: ECS kontejneri

Kad završiš EC2 deo, sledeći logičan korak su kontejneri. Tada aplikacija više ne ide direktno na EC2 instancu, nego u Docker image koji se čuva u ECR-u i pokreće kroz ECS. ALB i dalje ostaje ispred aplikacije, ali umesto ka instancama routuje ka ECS taskovima.

To nije deo ovih zadataka, ali je prirodan nastavak. Ako ovaj deo budeš radio kasnije, cilj će biti da isti koncept infrastrukture prebaciš sa ručno konfigurisanih instanci na servis koji lakše skalira i lakše se deploy-uje.
