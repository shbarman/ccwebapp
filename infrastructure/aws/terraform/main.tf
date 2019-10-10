variable "vpc_regions"{
    type=string
    default="us-east-1"
}
variable "name"{
    type=string
    default="VPC"
}
variable "cidr_block"{
    type=string
    default="10.0.2.0/16"
}

variable "subnets" {
    description= "Enter CIDR for subnets"
  type = list(string)
  }


module "networking" {
  source = "./networking"
  vpc_regions="${var.vpc_regions}"
  name="${var.name}"
  cidr_block="${var.cidr_block}"
  subnets="${var.subnets}"

}