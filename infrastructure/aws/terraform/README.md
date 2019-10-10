# Terraform

## Installation

Download Terraform single binary file from the below link

[Terraform](https://www.terraform.io/)

## Setup

For User to able to make changes to your AWS account AWS_PROFILE should be set for IAM user as environment variables by the following commands

```bash
export AWS_ACCESS_KEY =(your access key)
export AWS_SECRET_KEY =(your secret access key)
```

## Steps

```bash
terraform init
terraform plan
terraform apply [variables and cidr blocks]
terraform destroy
```

## Explanation

1. export AWS_PROFILE = (env variable) -> to set the Profile for the current terraform session
2. terraform init -> tells Terraform to scan the code and read the providers to be downloaded for the execution
3. terraform plan -> to perform a refresh and create an execution plan
4. terraform apply -> to create the required cidr blocks/vpcs and subnets
5. terraform destroy -> destroys the mentioned vpc or subnet block
