# Terraform

Terraform scripts that I use in order to provision my servers (for testing purposes)

## Quickstart

To create the infra for Google Cloud

```bash
cd google
terraform init
# May require additional information such as Google Cloud Project ID
terraform plan -out initial.plan
# Applying plan
terraform apply initial.plan
```

To destroy it

```bash
cd google
terraform init
# May require additional information such as Google Cloud Project ID
terraform plan -out destroy.plan -destroy
# Applying plan
terraform apply destroy.plan
```

## Important aspects

Capability to set up bastion server -> internal servers should have access to the internet

```bash
ssh -A -J <username>@<bastion host ip> <username>@<internal server ip>
```

## Tripped problems

- Enabling/disabling certain components to be provisioned. Some blogs were mentioning of using `count` field and setting it to 0 to "disable it" and 1 to "enable it". Also, needed to create a range of servers based on some instance number - so hence, the following:

```
│ Error: Invalid combination of "count" and "for_each"
│ 
│   on main.tf line 180, in resource "google_compute_instance" "etcd":
│  180:   for_each = range(1,3,1)
│ 
│ The "count" and "for_each" meta-arguments are mutually-exclusive, only one should be used to be explicit about the number of
│ resources to be created.
```