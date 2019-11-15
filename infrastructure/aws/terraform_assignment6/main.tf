provider "aws" {
     region="us-east-1"
}

variable "VPC_ID"{
    description="Please enter your Virtual private Cloud Id"
    type=string
   
}

variable "ami_id"{
	description = "Enter AMI number"
	type=string
}

variable "bucketName"{
	description = "Enter Bucket Name like dev.bhfatnani.me"
	type=string
}
variable "EC2ServiceRoleName"{
	description = "Enter EC2ServiceRoleName"
	type=string
}
variable "route53Name"{
	description = "Enter route53Name"
	type=string  

}
variable "sslARN"{
	description="Enter sslARN"
	type=string 

}

module "ec2" {
    source = "./ec2"
    VPC_ID=var.VPC_ID
    ami_id=var.ami_id
    bucketName=var.bucketName
    EC2ServiceRoleName=var.EC2ServiceRoleName
    route53Name=var.route53Name
    sslARN=var.sslARN
}