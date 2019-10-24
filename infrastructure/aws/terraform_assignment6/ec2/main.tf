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

#APPLICATION SECURITY GROUP

data "aws_subnet_ids" "sbs" {
  vpc_id = var.VPC_ID
}


data "aws_subnet" "sb_cidr" {
 
  count = length(data.aws_subnet_ids.sbs.ids)
  id    = tolist(data.aws_subnet_ids.sbs.ids)[count.index]
  
}

 
 resource "aws_security_group" "application"{ 
   
    name        = "application"
      vpc_id=var.VPC_ID
     description = "Allow TLS inbound traffic"
   
    ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

     ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

     ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    
    tags={
     Name="application"
   }

  }

#CALLING RDS MODULE
module "rds_instance"{
  source = "../rds_instance"
  vpcId = var.VPC_ID
  subnet_ids_from_vpc="${data.aws_subnet.sb_cidr.0.id}"
  subnet1_id_from_vpc="${data.aws_subnet.sb_cidr.1.id}"
  
 security_group_id = [aws_security_group.application.id]
 
  
}

# CREATING AWS EC2 INSTANCE
resource "aws_instance" "example" {
  ami = var.ami_id
  instance_type = "t2.micro"
  subnet_id ="${data.aws_subnet.sb_cidr.0.id}"
  vpc_security_group_ids  =[aws_security_group.application.id]
  ebs_block_device{
    device_name="/dev/sdf"
    volume_size=20
    volume_type="gp2"
    delete_on_termination="true"
    
  }
 lifecycle{
  prevent_destroy="false"
  }
  depends_on=[module.rds_instance]
  key_name= "csye6225" 
  disable_api_termination="false"
  
}

# CREATING S3 BUCKET
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucketName
  acl = "private"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
  
  force_destroy = true

  lifecycle_rule {
    enabled = true

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 60
      storage_class = "GLACIER"
    }
  }
}

