# Terraform

Terraform scripts that I use in order to provision my servers (for testing purposes)

## Quickstart

To create the infra

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

## Common features

- Capability to set up bastion server -> internal servers should have access to the internet
  ```bash
  ssh -A -J <username>@<bastion host ip> <username>@<internal server ip>
  ```
- Note: for AWS, might require different users - see OS. https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/connect-to-linux-instance.html
- Set up of multiple servers (with attempts at better secured servers)
  - etcd server instances
  - TODO: mariadb
  - TODO: nats
  - TODO: simple golang web application + custom machine image + load balancing
  - TODO: simple golang web application to upload and download files into S3

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

## Useful references

- https://spacelift.io/blog/terraform-best-practices