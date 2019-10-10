variable "vpc_regions"{
    type=string
    default="us-east-1"
}
variable "name"{
    type=string
    default="VPC_Name"
}

provider "aws" {
    region = var.vpc_regions
}

#terraform apply -var="cidr_block= 10.0.0.0/16"
variable "cidr_block"{
    type=string
    default="10.0.2.0/16"
}
variable "subnets_cidr_block1"{
    type=string
    default="10.0.0.0/24"
}
variable "subnets_cidr_block2"{
    type=string
    default="10.0.0.0/24"
}
variable "subnets_cidr_block3"{
    type=string
    default="10.0.0.0/24"
}
variable "subnets" {
    description= "Enter CIDR for subnets"
  type = list(string)
  }



 resource "aws_vpc" "VPC_Def"{
     
     cidr_block= "${var.cidr_block}"
     enable_dns_hostnames= true
     enable_dns_support= true
     enable_classiclink_dns_support= true
     assign_generated_ipv6_cidr_block=false
     tags={
         Name= var.name
     }
 }

 resource "aws_subnet" "subnet1" {
     count= "${length(var.subnets)}"
     
    cidr_block="${element((var.subnets), count.index)}"
     vpc_id="${aws_vpc.VPC_Def.id}"
     availability_zone="us-east-1a"
     map_public_ip_on_launch=true
     tags={
         Name= "Subnet"
     }
 }

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.VPC_Def.id}"

  tags = {
    Name = "internet_GateWay"
  }
}