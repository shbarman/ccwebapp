  
variable "vpcId" {
  description = "VPC ID to attach the db instance"
}

variable "cidr_blocks" {
  description = "CIDR BLOCK for security group"
  default = "0.0.0.0/0"
}
variable "subnet_ids_from_vpc" {
	description = "Subnet ID0 "
}
variable "subnet1_id_from_vpc" {
	description = "Subnet ID1 "
}
variable "security_group_id"{
  description = "app security "
}


resource "aws_db_subnet_group" "default" {
  name        = "db_subnet_group2"
  description = "subnet_group_db"
  subnet_ids  = [var.subnet_ids_from_vpc, var.subnet1_id_from_vpc]
}

resource "aws_db_instance" "rds_instance" {

  identifier             = "csye6225-fall2019"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.medium"
  name                   = "csye6225"
  username               = "dbuser"
  password               = "Ubuntu123$"
  multi_az               = "false"
  publicly_accessible    = "true"
  skip_final_snapshot = "true"
  final_snapshot_identifier="csye6225"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
 db_subnet_group_name   = "${aws_db_subnet_group.default.id}"
 deletion_protection = "false"
}

resource "aws_dynamodb_table" "csye6225" {
  name           = "csye6225"
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"
  

    attribute {
    name = "id"
    type = "S"
  }
  
}


