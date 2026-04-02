# Terraform zadaci

Ovaj repozitorij je niz povezanih zadataka koji te vode od praznog AWS naloga do kompletne web infrastrukture. Svaki zadatak nastavlja gde je prethodni stao — ne preskaču se, svaki je korak dalje. Na kraju imaš VPC, privatne servere, load balancer, bazu, SSL sertifikat i custom domen, sve napisano u Terraformu.

---

## Zadatak 1: IAM setup sa S3 backend-om

Prvi zadatak postavlja temelje za ceo projekat. Praviš IAM korisnika `terraform-user` koji nema skoro nikakve dozvole — sme samo da čita i piše u S3 bucket gde se čuva Terraform state, i da preuzme (assume) rolu `TerraformAdminRole`. Ta rola ima široke dozvole za kreiranje resursa, ali je korisnik ne koristi direktno — Terraform provider je "oblači" svaki put kad treba nešto napraviti. Tako je korisnik potpuno ograničen, a Terraform ipak može da kreira šta treba. State bucket se pravi van Terraform koda, sa versioningom i enkripcijom, da tvoj infrastrukturni kod nikad ne bude u istom repu sa stvarnim stanjem infrastrukture.

Ovde učiš razliku između korisnika i role u AWS-u, kako radi assume role mehanizam, i zašto je važno da state bude odvojen od koda. Verifikacija je jednostavna — pokreneš `terraform apply` i proveriš da su resursi kreirani preko role, ne preko direktnih kredencijala.

---

## Zadatak 2: SSH key pair, port 22, SSM Session Manager

Sada kad imaš EC2 instancu, treba ti način da joj pristupiš. Ovaj zadatak uvodi dva pristupa. Prvi je klasični SSH — generišeš ključ sa `ssh-keygen`, dodaješ javni ključ u AWS kao `aws_key_pair` resurs, i otvaraš port 22 u security grupi. Radi, ali port 22 otvoren za ceo internet je rizik. Drugi pristup je SSM Session Manager — AWS servis koji ti daje shell pristup instanci bez ikakvog otvorenog porta. Instanca treba IAM Instance Profile sa `AmazonSSMManagedInstanceCore` policy-jem, i SSM Agent koji je već instaliran na Amazon Linux 2023 komunicira outbound na port 443.

Glavna stvar koju ovde shvataš je da Instance Profile nije isto što i IAM Role — EC2 ne može koristiti rolu direktno, treba joj omotač koji se zove Instance Profile. Takođe učiš da je security grupa stateful — ako dozvoliš inbound na portu 22, odgovor automatski prolazi nazad bez dodatnog pravila.

---

## Zadatak 3: Private subnet, VPC endpointi, Secrets Manager

Ovaj zadatak izoluje EC2 instancu od interneta. Premestaš je iz public u private subnet — subnet koji nema rutu ka Internet Gateway-u. To znači da instanca nema javnu IP adresu i ne može komunicirati sa ničim van VPC-a. Ali SSM i dalje treba da radi, i zato praviš tri VPC Interface Endpointa (za ssm, ssmmessages i ec2messages) koji uspostavljaju privatnu vezu ka AWS servisima kroz AWS backbone, bez prolaska kroz internet. Ključni detalj je `private_dns_enabled = true` — bez toga bi DNS i dalje razrešavao na javnu IP adresu, a instanca nema internet da do nje dođe.

SSH se potpuno uklanja — port 22 se briše iz security grupe. Umesto toga, SSH ključ se generiše u Terraformu pomoću `tls_private_key` resursa i čuva u Secrets Manager. Tako niko ne drži privatni ključ na lokalnom disku, a ako zatreba, može se preuzeti iz AWS konzole. Bitno: kad promeniš `subnet_id` ili `key_name` na EC2 instanci, Terraform mora da je uništi i ponovo kreira — AWS ne dozvoljava te promene u mestu.

---

## Zadatak 4: NAT Gateway + S3 pristup + SSH tunel

Instanca je sada u private subnetu i nema internet. Ovaj zadatak joj daje izlazni pristup ka internetu kroz NAT Gateway. NAT se postavlja u public subnet sa Elastic IP adresom, a u private route table se dodaje ruta 0.0.0.0/0 koja usmerava sav saobraćaj ka NAT Gateway-u. Instanca sada može da pokreće `yum update` i slične stvari, ali niko spolja ne može da joj priđe — to je jednosmerni pristup. Pored toga, praviš i S3 Gateway VPC Endpoint koji je besplatan i omogućava S3 pristup bez prolaska kroz NAT.

Takođe se uvodi SSH preko SSM tunela — dodaješ ProxyCommand u `~/.ssh/config` koji koristi SSM kao transport, pa možeš koristiti standardne SSH komande bez otvorenog porta. Ovde shvataš razliku između Gateway endpointa (besplatan, samo za S3 i DynamoDB) i Interface endpointa (plaća se, ali radi za sve servise).

---

## Zadatak 5: RDS MySQL baza + Secrets Manager

Vreme je za bazu podataka. Praviš MySQL 8.0 RDS instancu u private subnetu sa `publicly_accessible = false` — niko spolja ne može da joj priđe, čak ni ako zna adresu. RDS zahteva DB Subnet Group sa najmanje dva subneta u različitim AZ-ama, čak i kad koristiš single-AZ instancu — AWS to traži jer mora postojati opcija za failover. Security grupa za RDS dozvoljava port 3306 samo od EC2 security grupe, ne od CIDR blokova — to je tzv. security group chaining, i precizniji je jer se automatski prilagođava promenama IP adresa.

Lozinka za bazu se generiše pomoću `random_password` resursa u Terraformu — nikad se ne pojavljuje u kodu, samo u state fajlu. Svi podaci za konekciju (host, port, user, password, dbname) čuvaju se u Secrets Manager kao JSON objekat, i EC2 dobija IAM politiku da čita taj secret. Na Free Tier je ovo besplatno (750 sati mesečno, 12 meseci).

---

## Zadatak 6: ALB i NLB — dva pristupa load balancing-u

Ovaj zadatak upoređuje dva tipa load balancera. ALB (Application Load Balancer) radi na Layer 7 — razume HTTP protokol, može rutirati po URL putanji, headerima, hostname-u. Ima svoju security grupu i menja source IP adresu, pa EC2 vidi zahteve kao da dolaze od ALB-a, ne od klijenta. Zato koristiš security group chaining — EC2 dozvoljava HTTP samo od ALB security grupe. ALB zahteva najmanje dva subneta u različitim AZ-ama i automatski radi health check na targetima.

NLB (Network Load Balancer) radi na Layer 4 — ne razume HTTP, samo prosleđuje TCP pakete. Nema security grupu i zadržava originalni klijentov IP. Brži je od ALB (oko 100μs naspram 400μs) i koristi se za SSH, gaming servere, IoT protokole. Poenta zadatka je da shvatiš kada koristiti koji: ALB za web saobraćaj (routing, WAF, SSL terminacija), NLB za sve ostalo gde treba brzina ili static IP.

---

## Zadatak 7: RDS + PHP Web App + NLB HTTP listener

Ovaj zadatak spaja bazu i web prikaz. Na EC2 instanci instaliraš PHP i praviš `db.php` stranicu koja čita podatke iz MySQL baze i prikazuje ih u browseru. Kredencijali se ne upisuju ručno — `user_data` skripta pri pokretanju preuzima ih iz Secrets Manager i snima u lokalni JSON fajl. Pošto NAT Gateway ili VPC endpointi ponekad nisu odmah dostupni pri boot-u, koristi se retry petlja (12 pokušaja sa po 10 sekundi) koja čeka da Secrets Manager postane dostupan.

NLB dobija HTTP listener na portu 80 koji prosleđuje TCP saobraćaj ka EC2 na portu 80. Rezultat je web stranica dostupna na `http://<nlb_dns>/db.php` koja pokazuje tabele i podatke iz baze. Ovde učiš da `user_data` može da instalira pakete, kreira fajlove i pokreće servise pri prvom pokretanju instance, i da file permissions moraju biti pažljivo postavljeni — `chmod 640` za JSON sa kredencijalima (root i apache mogu čitati), `chmod 600` za `.my.cnf` (samo owner). (proveri razlike 644, 640, 600)

---

## Zadatak 8: ALB sa 2 EC2 instance (High Availability)

Jedna instanca je single point of failure. Ovaj zadatak postavlja dve EC2 instance u dve različite Availability Zone, iza jednog Application Load Balancera. ALB automatski raspoređuje zahteve između njih (round-robin), i ako jedna instanca prestane da odgovara na health check, ALB prestaje da joj šalje saobraćaj i sve ide na preostalu zdravu instancu. Korisnik ni ne primećuje da je jedna mašina pala.

NLB se zakomentariše — ALB preuzima sav HTTP saobraćaj, a SSH pristup ide isključivo preko SSM Session Managera. Uvode se feature flagovi (`create_alb`, `create_rds`) koji kontrolišu da li se određeni delovi infrastrukture kreiraju, i `ec2_instance_count` koji određuje broj instanci. Sa ALB je uvek 2 (za HA), bez ALB je 1. Cross-zone load balancing je uključen po defaultu — ALB ravnomerno deli zahteve i na targete u drugoj AZ, ne samo na one u istoj. 

---

## Zadatak 9: ALB HA failover testiranje

Ovaj zadatak ne dodaje novi kod — koristiš postojeću ALB infrastrukturu sa dve instance i testiraš šta se dešava kad padnu. Prvo proveriš da obe instance odgovaraju na HTTP zahteve. Zatim ugasiš jednu — ALB nastavlja da radi sa drugom, saobraćaj automatski prelazi na zdravu instancu. Zatim ugasiš i drugu — ALB više nema nijedan zdrav backend i vraća HTTP 503 Service Unavailable. Na kraju ih ponovo pokreneš i posmatraš kako se vraćaju u healthy stanje.

Ključno saznanje je da failover nije trenutan. Health check radi na svakih 30 sekundi, i treba mu 3 uzastopna neuspeha da proglasi target nezdravim, plus 2 uspeha da ga vrate. To znači 1-2 minuta od trenutka pada instance do prebacivanja saobraćaja. Takođe shvataš da backend instance ne moraju biti javno dostupne — ALB komunicira sa njima unutar VPC-a, i da je jedan zdrav backend dovoljan da aplikacija nastavi da radi.

---

## Zadatak 10: HTTPS/SSL sa ACM certifikatom i Route 53

Poslednji zadatak dodaje HTTPS i custom domen. Kreiraš Route 53 hosted zonu za tvoj domen, A alias record koji pokazuje na ALB, i ACM (AWS Certificate Manager) SSL sertifikat sa DNS validacijom. ACM daje besplatan sertifikat za AWS resurse, i automatski se obnavlja. Na ALB se dodaje HTTPS listener na portu 443, a postojeći HTTP listener na portu 80 se pretvara u redirect na HTTPS (301). Od tog trenutka, svaki HTTP zahtev se automatski prebacuje na HTTPS.

 
---

## Sledeći korak: ECS kontejneri

Sledeća faza posle EC2 instanci su kontejneri. ECR (Elastic Container Registry) ti daje privatni Docker registry gde smeštaš slike aplikacije — AWS automatski skenira na ranjivosti. ECS (Elastic Container Service) pokreće te kontejnere na AWS-u. Sa Fargate launch type ne upravljaš serverima uopšte — definiseš Task Definition (koji image, koliko CPU, memorije, koji portovi) i Service koji održava željeni broj pokrenutih kontejnera i restartuje pale.

Šta se menja u odnosu na sadašnji setup: umesto httpd na EC2 instanci, aplikacija radi u Docker kontejneru. ALB ostaje isti, ali umesto ka EC2 instancama rutira ka ECS taskovima. Prednost je lakši deployment (nova verzija = novi image), nema upravljanja operativnim sistemom, i bolje skaliranje jer ECS Service može automatski dodati ili ukloniti kontejnere.
