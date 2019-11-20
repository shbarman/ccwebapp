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

#  resource "aws_subnet" "subnet1" {
#      count= "${length(var.subnets)}"
     
#     cidr_block="${element((var.subnets), count.index)}"
#      vpc_id="${aws_vpc.VPC_Def.id}"
#      #availability_zone="us-east-1a"
#      map_public_ip_on_launch=true
#      tags={
#          Name= "Subnet"
#      }
#  }

 resource "aws_route_table" "vpcroute_table" {
    vpc_id = aws_vpc.VPC_Def.id

    tags = {
        "Name" = "Route Table"
    }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.VPC_Def.id}"

  tags = {
    Name = "internet_GateWay"
  }
}

resource "aws_route" "internet_access" {
    route_table_id = aws_route_table.vpcroute_table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
}

data "aws_availability_zones" "available" {
}

resource "aws_subnet" "subnet1" {
    vpc_id = aws_vpc.VPC_Def.id
    cidr_block = "${element((var.subnets), 0)}"
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[0]

    tags = {
        "Name" = "Subnet One"
    }
}

resource "aws_subnet" "subnet2" {
    vpc_id = aws_vpc.VPC_Def.id
    cidr_block = "${element((var.subnets), 1)}"
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[1]

    tags = {
        "Name" = "Subnet Two"
    }
}

resource "aws_subnet" "subnet3" {
    vpc_id = aws_vpc.VPC_Def.id
    cidr_block = "${element((var.subnets), 2)}"
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[2]

    tags = {
        "Name" = "Subnet Three"
    }
    
}

resource "aws_route_table_association" "association_one" {
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.vpcroute_table.id
}

resource "aws_route_table_association" "association_two" {
    subnet_id = aws_subnet.subnet2.id
    route_table_id = aws_route_table.vpcroute_table.id
}

resource "aws_route_table_association" "association_three" {
    subnet_id = aws_subnet.subnet3.id
    route_table_id = aws_route_table.vpcroute_table.id
}
