data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

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


resource "aws_iam_instance_profile" "ec2instanceprofile" {
  name = "an_example_instance_profile_name"
  role = var.EC2ServiceRoleName
  depends_on=[aws_iam_role.EC2ServiceRole]
}

# CREATING AWS EC2 INSTANCE
resource "aws_instance" "example" {
  ami = var.ami_id
  instance_type = "t2.micro"
  subnet_id ="${data.aws_subnet.sb_cidr.0.id}"
  vpc_security_group_ids  =[aws_security_group.application.id]
  iam_instance_profile = "${aws_iam_instance_profile.ec2instanceprofile.name}"
  ebs_block_device{
    device_name="/dev/sdf"
    volume_size=20
    volume_type="gp2"
    delete_on_termination="true"
    
  }
 lifecycle{
  prevent_destroy="false"
  }
  depends_on=[module.rds_instance, aws_s3_bucket.bucket, aws_iam_instance_profile.ec2instanceprofile]
  key_name= "csye6225" 
  disable_api_termination="false"


  tags = {
    Name = "Web Server"
  }
  
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



resource "aws_iam_policy" "s3Bucket-CRUD-Policy" {
  name        = "s3Bucket-CRUD-Policy"
  description = "A Upload policy"
  depends_on = [aws_s3_bucket.bucket]
  policy = <<EOF
{
          "Version" : "2012-10-17",
          "Statement": [
            {
              "Sid": "AllowGetPutDeleteActionsOnS3Bucket",
              "Effect": "Allow",
              "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject","s3:GetObjectAcl", "s3:GetObjectVersionAcl", "s3:ListBucket","s3:ListAllMyBuckets"],
              "Resource": ["${aws_s3_bucket.bucket.arn}/*"]
            }
          ]
        }
EOF
}


resource "aws_iam_role_policy_attachment" "EC2ServiceRole_CRUD_policy_attach" {
  role       =  var.EC2ServiceRoleName
  policy_arn = "${aws_iam_policy.s3Bucket-CRUD-Policy.arn}"
}


