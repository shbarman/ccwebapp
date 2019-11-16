data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

variable "VPC_ID"{
    description="Please enter your Virtual private Cloud Id"
    type=string
   
}
variable "route53Name"{
	description="Enter route53Name"
	type=string 
}
variable "sslARN"{
	description="Enter sslARN"
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
variable "dbuser"{	
	type=string
  default="dbuser"
}
variable "dbpassword"{	
	type=string
  default="Ubuntu123$"
}


#APPLICATION SECURITY GROUP

data "aws_subnet_ids" "sbs" {
  vpc_id = var.VPC_ID
}
data "aws_availability_zones" "all" {}

data "aws_subnet" "sb_cidr" {
 
  count = length(data.aws_subnet_ids.sbs.ids)
  id    = tolist(data.aws_subnet_ids.sbs.ids)[count.index]
  #id    = "${data.aws_subnet_ids.sbs.ids[count.index]}"
  
}

 
 resource "aws_security_group" "application"{ 
   
    name        = "application"
      vpc_id=var.VPC_ID
     description = "Allow TLS inbound traffic"
   
    

     ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = ["${aws_security_group.lb.id}"]
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
  depends_on = [aws_iam_role_policy_attachment.EC2ServiceRole_CRUD_policy_attach]
  role = var.EC2ServiceRoleName
}

#CALLING S3 BUCKET MODULE
module "s3_bucket"{
  source = "../s3_bucket"
  bucketName = var.bucketName
  
}









#  # CREATING AWS EC2 INSTANCE
#  resource "aws_instance" "example" {
#    ami = var.ami_id
#    instance_type = "t2.micro"
#    user_data = "${templatefile("script/db_details.sh",
#                                      {
#                                        domain = module.rds_instance.rds_endpoint,
#                                        bucketName = module.s3_bucket.s3_bucketId,
#                                        dbuser = var.dbuser,
#                                        dbpassword = var.dbpassword
#                                      })}"
  
  
#    #"${data.template_file.db_details.rendered}"
#    subnet_id ="${data.aws_subnet.sb_cidr.0.id}"
#    vpc_security_group_ids  =[aws_security_group.application.id]
#    iam_instance_profile = "${aws_iam_instance_profile.ec2instanceprofile.name}"
#    ebs_block_device{
#      device_name="/dev/sdf"
#      volume_size=20
#      volume_type="gp2"
#      delete_on_termination="true"  
#    }
  
#   lifecycle{
#    prevent_destroy="false"
#    }
#    depends_on=[module.rds_instance, module.s3_bucket, aws_iam_instance_profile.ec2instanceprofile]
#    key_name= "csye6225" 
#    disable_api_termination="false"


#    tags = {
#      Name = "Web Server"
#    }
  
#  }

resource "aws_lb" "loadBalance" {
  name               = "loadBalance"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.lb.id}"]
  #subnets            = "${data.aws_subnet.sb_cidr.*.cidr_block}"
  subnets = "${data.aws_subnet.sb_cidr.*.id}"

  #enable_deletion_protection = true

  # access_logs {
  #   bucket  = "${aws_s3_bucket.lb_logs.bucket}"
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "dev"
  }
}

#AWS Load Balancer Target Group
resource "aws_lb_target_group" "awsLbTargetGroup" {
  name = "awsLbTargetGroup"
  target_type = "instance"
  port = 443
  protocol = "HTTPS"
  vpc_id = var.VPC_ID
}


#AWS LoadBalancer Security Group
resource "aws_security_group" "lb" {
  name = "lb"
  vpc_id=var.VPC_ID
  egress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




#Auto Scaling Launch Configuration
resource "aws_launch_configuration" "asg_launch_config" {
  image_id = var.ami_id
  instance_type = "t2.micro"
  user_data = "${templatefile("script/db_details.sh",
                                    {
                                      domain = module.rds_instance.rds_endpoint,
                                      bucketName = module.s3_bucket.s3_bucketId,
                                      dbuser = var.dbuser,
                                      dbpassword = var.dbpassword
                                    })}"

  iam_instance_profile = "${aws_iam_instance_profile.ec2instanceprofile.name}"
  depends_on=[module.rds_instance, module.s3_bucket, aws_iam_instance_profile.ec2instanceprofile]
  key_name= "csye6225" 
  ebs_block_device{
     device_name="/dev/sdf"
     volume_size=20
     volume_type="gp2"
     delete_on_termination="true"  
    } 
    security_groups= [aws_security_group.application.id]
    #associate_public_ip_address=true
  }





# resource "aws_autoscaling_group" "asg_launch_config"{
#   launch_configuration = "${aws_launch_configuration.aws_launch.id}"
#   name= "asg_launch_config" 
#   max_size = 10
#   min_size = 3
# }




resource "aws_iam_policy" "s3Bucket-CRUD-Policy" {
  name        = "s3Bucket-CRUD-Policy"
  description = "A Upload policy"
  depends_on = [module.s3_bucket]
  policy = <<EOF
{
          "Version" : "2012-10-17",
          "Statement": [
            {
              "Sid": "AllowGetPutDeleteActionsOnS3Bucket",
              "Effect": "Allow",
              "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject","s3:GetObjectAcl", "s3:GetObjectVersionAcl", "s3:ListBucket","s3:ListAllMyBuckets"],
              "Resource": ["${ module.s3_bucket.s3_bucketArn}","${ module.s3_bucket.s3_bucketArn}/*"]
            }
          ]
        }
EOF
}


resource "aws_iam_role_policy_attachment" "EC2ServiceRole_CRUD_policy_attach" {
  role       =  var.EC2ServiceRoleName
  policy_arn = "${aws_iam_policy.s3Bucket-CRUD-Policy.arn}"
}

#AWS Autoscaling Group 
resource "aws_autoscaling_group" "csye6225-autoscaling-deployment" {
  #depends_on = [aws_codedeploy_deployment_group.csye6225-webapp-deployment, aws_codedeploy_app.csye6225-webapp]
  name= "csye6225-autoscaling-deployment"
  max_size = 10
   min_size = 3
  # desired_capacity = 3
  # default_cooldown = 10
  target_group_arns = ["${aws_lb_target_group.awsLbTargetGroup.arn}"]
  launch_configuration = "${aws_launch_configuration.asg_launch_config.id}"
  vpc_zone_identifier = ["${data.aws_subnet.sb_cidr.0.id}", "${data.aws_subnet.sb_cidr.1.id}"]
}

#Scale Up
resource "aws_autoscaling_policy" "csye6225-autoscaling-deployment-scale-up" {
    name = "csye6225-autoscaling-deployment-scale-up"
    scaling_adjustment = 1
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    autoscaling_group_name = "${aws_autoscaling_group.csye6225-autoscaling-deployment.name}"
}
#Scale Down
resource "aws_autoscaling_policy" "csye6225-autoscaling-deployment-scale-down" {
    name = "csye6225-autoscaling-deployment-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 60
    autoscaling_group_name = "${aws_autoscaling_group.csye6225-autoscaling-deployment.name}"
}

#Alarm when memory load is high
resource "aws_cloudwatch_metric_alarm" "memory-high" {
    alarm_name = "mem-util-high-agents"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "60"
    statistic = "Average"
    threshold = "5"
      dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.csye6225-autoscaling-deployment.name}"
  }
    alarm_description = "This metric monitors ec2 memory for high utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.csye6225-autoscaling-deployment-scale-up.arn}"
    ]
}

#Alarm when memory is low
resource "aws_cloudwatch_metric_alarm" "memory-low" {
    alarm_name = "mem-util-low-agents"
    comparison_operator = "LessThanOrEqualToThreshold"
    evaluation_periods = "2"
    metric_name = "MemoryUtilization"
    namespace = "System/Linux"
    period = "60"
    statistic = "Average"
    threshold = "3"
    dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.csye6225-autoscaling-deployment.name}"
  }
    alarm_description = "This metric monitors ec2 memory for low utilization on agent hosts"
    alarm_actions = [
        "${aws_autoscaling_policy.csye6225-autoscaling-deployment-scale-down.arn}"
    ]
}

#AWS route53 record
resource "aws_route53_record" "csye-ns" {
   zone_id = "ZT6PAAOHNEPLD"
   name = "${var.route53Name}."
   type    = "A"
   alias {
     name                   = "${aws_lb.loadBalance.dns_name}"
     zone_id                = "${aws_lb.loadBalance.zone_id}"
     evaluate_target_health = true
   }

   }

#AWS Listener
resource "aws_lb_listener" "loadbalnce_listener" {
  load_balancer_arn = "${aws_lb.loadBalance.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = "${var.sslARN}"
  default_action {
    type = "forward"
    target_group_arn = "${aws_lb_target_group.awsLbTargetGroup.arn}"
  }
}
