Zadatak: Kreiranje Terraform setup-a sa
IAM korisnikom i S3 backend-om
Cilj
Nauciti kako da:
• Kreiraš AWS IAM korisnika koji se koristi isključivo za Terraform.
• Napraviš IAM rolu sa privilegijama za upravljanje resursima (VPC, EC2, S3, RDS, ECS, EKS, CloudWatch...itd).
• Omogućiš Terraform korisniku da assume role za upravljanje resursima.
• Kreiraš S3 bucket koji služi kao Terraform backend (state) sa minimalnim pristupom.
Napomena: Za pocetak mozes koristiti s3 * privilegije za Terraform user radi testiranja, ali ćemo na kraju zadatka uraditi hardening i dati minimalne potrebne polise.
Koraci
1. Kreirati Terraform IAM korisnika
• Kreiraj IAM korisnika terraform-user sa programmatic access (Access Key +
Secret Key).
• Terraform user ne upravlja infrastrukturom direktno - svi resursi se kreiraju preko assume role (TerraformAdminRole).
• Direktan pristup Terraform user-a je potreban samo za backend bucket:
1. s3 :ListBucket - da Terraform može da vidi state fajlove u bucket-u
2. s3 GetObject i s3 :PutObject - za čitanje i pisanje state fajlova

3. opciono: s3 :GetObjectVersion i s3 :Put0bjectAc1 -ako koristis
versioning
• Credentials Terraform user-a se mogu postaviti preko:
1. terraform. tfvars fajla sa varijablama aws_access_key i
aws_secret_key
2. Environment varijabli: TF_VAR_aws_access_key i TF_VAR_aws_secret_key
3. AWS CLI default profila kreiranog komandom aws configure
Preporuka: koristiti default profil ili environment varijable, da se ne hardkodira access key u Terraform fajlovima.


2. Kreirati IAM rolu za Terraform
• Kreiraj rolu TerraformAdminRole.
• Dodeli roli privilegije za upravljanje resursima koje Terraform kreira:
• VPC, EC2, S3 (za resurse, ne backend), RDS, ECS, EKS, CloudWatch
• Podesi Trust Relationship tako da terraform-user moze da assume rolu:
• Terraform user ne pristupa resursima direktno, već sve akcije idu preko role.
3. Kreirati S3 bucket za Terraform state
• Kreirati bucket terraform-state-bucket.
• Terraform user treba da ima pristup samo backend bucket-u:
GetObject, Putobject za state fajlove
ListBucket za pregled bucket-a


opciono: GetobjectVersion, PutObjectAcl ako koristiš versioning
• Aktivirati versioning radi sigurnosti i zaštite state fajlova.
4. Terraform konfiguracija
• Napraviti Terraform provider konfiguraciju koja:
koristi IAM user credentials (access_key i secret_key) ili default profil za pristup S3 backend-u
assume role ka TerraformAdminRole za kreiranje resursa
• Testirati pristup tako što ćeš kreirati:
S3 bucket (resurs, ne backend)
• EC2 instancu
• VPC
Sigurnosna napomena
• Terraform user direktno pristupa samo backend bucket-u.
• Svi ostali resursi se kreiraju preko assume role (TerraformAdminRole).
• Nakon zavrsetka zadatka, polise za backend S3 bucket treba da se harduju na minimalne privilegije:
• ListBucket
• Getobject, Putobject
• GetobjectVersion, PutObjectAc1 (ako se koristi versioning)
