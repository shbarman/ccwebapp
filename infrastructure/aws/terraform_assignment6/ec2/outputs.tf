output "security_group_id" {
    value = aws_security_group.application.id
}

output "subnet_ids_from_vpc" {
   value = "${data.aws_subnet.sb_cidr.0.id}"
  # ["${data.aws_subnet.sb_cidr.*.cidr_block}"]
}

output "subnet1_id_from_vpc" {
   value = "${data.aws_subnet.sb_cidr.1.id}"
  # ["${data.aws_subnet.sb_cidr.*.cidr_block}"]
}


output "vpcId" {
   value = var.VPC_ID
}

 
