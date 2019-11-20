# Terraform

## Installation

Download Terraform single binary file from the below link

[Terraform](https://www.terraform.io/)

## Setup

For User to able to make changes to your AWS account AWS_PROFILE should be set for IAM user as environment variables by the following commands:

```bash
export AWS_ACCESS_KEY =(your access key)
export AWS_SECRET_KEY =(your secret access key)
```

## Steps to run  terraform

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
5. terraform destroy -> destroys the mentioned vpc or subnet block basically our plan which we applied using terraform apply
6. For updated terraform rds_instance 
        The rds_instance ingress rule allows the security group set in the webapp application
        ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ** for the application cidr **
    security_groups = " ** Application security group **"  
    
  }
 7. For application terraform aws_instance
        The security group applied for the application should egress all traffic to the rds instance for connectivity.
  8. After launching application in ec2 the following should provided through cli
        RDS DOMAIN NAME
        DATABASE USERNAME
        PASSWORD
        AWS ACCESS KEY
        AWS SECRET KEY       

