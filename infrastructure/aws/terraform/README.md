#Terraform

##Installation##

Download Terraform single binary file from the below link

[Terraform](https://www.terraform.io/)

##Setup##

For User to able to make changes to your AWS account AWS_PROFILE should be set for IAM user as environment variables by the following commands

```bash
export AWS_ACCESS_KEY =(your access key)
export AWS_SECRET_KEY =(your secret access key)
```

##Steps##

```bash
terraform init
terraform plan
terraform apply [variables and cidr blocks]
terraform destroy
```

##Explanation##
terraform init -> tells Terraform to scan the code and read the providers to be downloaded for the execution
terraform plan -> to perform a refresh and create an execution plan
