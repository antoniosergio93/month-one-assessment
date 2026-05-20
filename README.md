
# AWS Infrastructure Deployment (Terraform)

This project contains Terraform configuration to deploy a web application infrastructure on AWS as part of the TechCorp junior cloud engineer assessment.

## Requirements

* Terraform installed
* AWS credentials configured (`aws configure`)

## Deployment

Initialize Terraform:

```bash
terraform init
```

Preview the infrastructure:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

## Destroy Infrastructure

To remove all created resources:

```bash
terraform destroy
```

## Notes

Ensure your AWS credentials have sufficient permissions before running the commands.

---
