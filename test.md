# Commands 

```bash
ssh-keygen -t ed25519 -f ~/.ssh/terraform-zadaci -C "terraform-zadaci"
```


```bash
ssh -i ~/.ssh/terraform-zadaci ec2-user@$(terraform output -raw test_ec2_public_ip)
```

```bash
ssh -i ~/.ssh/terraform-zadaci ec2-user@$(terraform output -raw test_ec2_public_ip)
```


```bash
aws ssm start-session --profile terraform-admin --target $(terraform output -raw test_ec2_instance_id)
```