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


variable "dbuser"{	
	type=string
  default="dbuser"
}
variable "dbpassword"{	
	type=string
  default="Ubuntu123$"
}

variable "EC2ServiceRoleName"{
	description = "Enter EC2ServiceRoleName"
	type=string
}
variable "CodeDeployServiceARN"{
	description = "Enter CodeDeployServiceARN"
	type=string

}

variable "Hosted_ZONE_ID" {
	description = "Enter ROUTE53 hosted zone ID"
	type=string
}
variable "domain"{
  type=string
}

variable "lambda_s3_bucket"{
  type=string
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
  port = 8080
  protocol = "HTTP"
  vpc_id = var.VPC_ID
}


#AWS LoadBalancer Security Group
resource "aws_security_group" "lb" {
  name = "lb"
  vpc_id=var.VPC_ID

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
      egress {
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
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
  max_size = 5
   min_size = 3
  desired_capacity = 3
  default_cooldown = 60
  target_group_arns = ["${aws_lb_target_group.awsLbTargetGroup.arn}"]
  launch_configuration = "${aws_launch_configuration.asg_launch_config.id}"
  vpc_zone_identifier = ["${data.aws_subnet.sb_cidr.0.id}", "${data.aws_subnet.sb_cidr.1.id}"]
  tag{
    key="env"
    propagate_at_launch=true
    value="prod"
  }
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
resource "aws_cloudwatch_metric_alarm" "CPUAlarm-High" {
  alarm_name = "CPUAlarmHighAgent"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 2
  threshold = 5
  metric_name = "CPUUtilization"
  statistic = "Average"
  namespace = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.csye6225-autoscaling-deployment.name}"
  }

  alarm_actions = [aws_autoscaling_policy.csye6225-autoscaling-deployment-scale-up.arn]
  alarm_description = "Scale-up if CPU > 5%"
  period = 300
}

#Alarm when memory is low
resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name = "CPUAlarmLowAgent"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = 2
  threshold = 3
  metric_name = "CPUUtilization"
  statistic = "Average"
  namespace = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = "${aws_autoscaling_group.csye6225-autoscaling-deployment.name}"
  }
  alarm_actions = [aws_autoscaling_policy.csye6225-autoscaling-deployment-scale-down.arn]
  alarm_description = "Scale-up if CPU < 3%"
  period = 300
}

#AWS route53 record
resource "aws_route53_record" "csye-ns" {
   zone_id = "${var.Hosted_ZONE_ID}"
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



resource "aws_codedeploy_app" "csye6225-webapp" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}


resource "aws_codedeploy_deployment_group" "csye6225-webapp-deployment" {
  app_name              = "${aws_codedeploy_app.csye6225-webapp.name}"
  deployment_group_name = "csye6225-webapp-deployment"
  depends_on=[aws_autoscaling_group.csye6225-autoscaling-deployment]
  service_role_arn      = "${var.CodeDeployServiceARN}"
  autoscaling_groups = ["csye6225-autoscaling-deployment"]
  
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = "Web Server"
    }
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  deployment_config_name = "CodeDeployDefault.AllAtOnce"

  auto_rollback_configuration {
    enabled = true
    events  = [
            "DEPLOYMENT_FAILURE"
          ]
  }
}

resource "aws_iam_policy" "CircleCI-Code-Deploy" {
  name        = "CircleCI-Code-Deploy"
  description = "A Upload policy"
  depends_on = [aws_codedeploy_deployment_group.csye6225-webapp-deployment, aws_codedeploy_app.csye6225-webapp]

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision",
        "codedeploy:ListApplicationRevisions"
      ],
      "Resource": [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:${aws_codedeploy_app.csye6225-webapp.name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:${aws_codedeploy_app.csye6225-webapp.name}/${aws_codedeploy_deployment_group.csye6225-webapp-deployment.deployment_group_name}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "CircleCI-Code-Deploy-policy-attach" {
  name       = "CircleCI-Code-Deploy"
  users      = ["circleci"]
  policy_arn = "${aws_iam_policy.CircleCI-Code-Deploy.arn}"
}





resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambdafunc.function_name}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.EmailNotificationRecipeEndpoint.arn}"
  depends_on      = [aws_lambda_function.lambdafunc]
}


resource "aws_sns_topic" "EmailNotificationRecipeEndpoint" {
  name = "EmailNotificationRecipeEndpoint"
}

resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = "${aws_sns_topic.EmailNotificationRecipeEndpoint.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.lambdafunc.arn}"
  depends_on      = [aws_lambda_function.lambdafunc]
}


resource "aws_iam_policy" "CircleCI-update-lambda-To-S3" {
  name        = "CircleCI-update-lambda-To-S3"
  description = "A Upload policy"
  depends_on = [aws_lambda_function.lambdafunc]
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "ActionsWhichSupportResourceLevelPermissions",
            "Effect": "Allow",
            "Action": [
                "lambda:AddPermission",
                "lambda:RemovePermission",
                "lambda:CreateAlias",
                "lambda:UpdateAlias",
                "lambda:DeleteAlias",
                "lambda:UpdateFunctionCode",
                "lambda:UpdateFunctionConfiguration",
                "lambda:PutFunctionConcurrency",
                "lambda:DeleteFunctionConcurrency",
                "lambda:PublishVersion"
            ],
            "Resource": "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:sns_lambda_function"
        }
   ]
}
EOF
}

resource "aws_iam_policy" "EC2-To-SNS" {
  name        = "EC2-To-SNS"
  description = "A Upload policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
   "Statement": [
            {
              "Sid": "AllowEC2ToPublishToSNSTopic",
              "Effect": "Allow",
              "Action": ["sns:Publish",
              "sns:CreateTopic"],
              "Resource": "${aws_sns_topic.EmailNotificationRecipeEndpoint.arn}"
            }
          ]
}
EOF

}
resource "aws_iam_role_policy_attachment" "EC2ServiceRole_sns_policy_attach" {
  role       = "${var.EC2ServiceRoleName}"
 # depends_on = [aws_iam_role.EC2ServiceRole]
  policy_arn = "${aws_iam_policy.EC2-To-SNS.arn}"
}

resource "aws_iam_policy_attachment" "circleci-update-policy-attach" {
  name       = "circleci-policy"
  users      = ["circleci"]
  policy_arn = "${aws_iam_policy.CircleCI-update-lambda-To-S3.arn}"
}


resource "aws_lambda_function" "lambdafunc" {

function_name = "sns_lambda_function"
  role          = "${aws_iam_role.CodeDeployAWSLabdaRole.arn}"
  handler       = "com.neu.LambdaEmail.EmailEvent::handleRequest"
  runtime       = "java8"
  s3_bucket = var.lambda_s3_bucket
  s3_key = "dummy.zip"
  memory_size     = 256
  timeout         = 180
  reserved_concurrent_executions  = 5
  environment  {
    variables = {
      domain = var.domain
      table  = module.rds_instance.dynamodb_table
    }
  }
  tags = {
    Name = "Lambda Email"
  }
}


resource "aws_iam_role" "CodeDeployAWSLabdaRole" {
  name = "iam_for_lambda_with_sns"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  tags = {
    Name = "CodeDeployAWSLabdaRole"
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda"
  depends_on = [aws_sns_topic.EmailNotificationRecipeEndpoint]
  policy = <<EOF
{
          "Version" : "2012-10-17",
          "Statement": [
            {
        "Sid" : "LambdaDynamoDBAccess",
        "Effect" : "Allow",
        "Action" : [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ],
         "Resource" : "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/csye6225"
      },
      {
        "Sid" : "LambdaSESAccess",
        "Effect": "Allow",
        "Action": [
          "ses:VerifyEmailAddress",
          "ses:SendEmail",
          "ses:SendRawEmail"
        ],
          "Resource": "arn:aws:ses:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:identity/*"
      },
      {
        "Sid" : "LambdaS3Access",
        "Effect": "Allow",
        "Action": [ "s3:GetObject"],
       "Resource": "arn:aws:s3:::${var.lambda_s3_bucket}/*"
      },
      {
        "Sid" : "LambdaSNSAccess",
        "Effect": "Allow",
        "Action": [ "sns:ConfirmSubscription"],
       "Resource": "${aws_sns_topic.EmailNotificationRecipeEndpoint.arn}"
      }
          ]
        }
EOF
}

resource "aws_iam_policy" "topic_policy" {
  name        = "Topic"
  description = ""
  depends_on  = [aws_sns_topic.EmailNotificationRecipeEndpoint]
  policy = <<EOF
{
          "Version" : "2012-10-17",
          "Statement": [
          {
        "Sid"     : "AllowEC2ToPublishToSNSTopic",
        "Effect"  : "Allow",
        "Action"  : [
            "sns:Publish",
            "sns:CreateTopic"
        ],
        "Resource": "${aws_sns_topic.EmailNotificationRecipeEndpoint.arn}"
      }
          ]
        }
  EOF
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attach_role" {
  role       = "${aws_iam_role.CodeDeployAWSLabdaRole.name}"
  depends_on = [aws_iam_role.CodeDeployAWSLabdaRole]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach_role" {
  role       = "${aws_iam_role.CodeDeployAWSLabdaRole.name}"
  depends_on = [aws_iam_role.CodeDeployAWSLabdaRole]
  policy_arn = "${aws_iam_policy.lambda_policy.arn}"
}

resource "aws_iam_role_policy_attachment" "topic_policy_attach_role" {
  role       = "${aws_iam_role.CodeDeployAWSLabdaRole.name}"
  depends_on = [aws_iam_role.CodeDeployAWSLabdaRole]
  policy_arn = "${aws_iam_policy.topic_policy.arn}"
}
resource "aws_cloudformation_stack" "waf" {
   name = "waf-stack"
   template_body=<<STACK
   {
    "AWSTemplateFormatVersion": "2010-09-09",
    "Description": "AWS WAF Basic OWASP Example Rule Set",
    
    "Resources": {
        "wafrSQLiSet": {
            "Type": "AWS::WAFRegional::SqlInjectionMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-detect-sqli"
                },
                "SqlInjectionMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrSQLiRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "mitigatesqli",
                "Name": {
                    "Fn::Sub": "WAF-mitigate-sqli"
                },
                "Predicates": [
                    {
                        "Type": "SqlInjectionMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrSQLiSet"
                        }
                    }
                ]
            }
        },
        "wafrAuthTokenStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-auth-tokens"
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "example-session-id",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "authorization"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ",
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafrAuthTokenRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "badauthtokens",
                "Name": {
                    "Fn::Sub": "WAF-detect-bad-auth-tokens"
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrAuthTokenStringSet"
                        }
                    }
                ]
            }
        },
        "wafrXSSSet": {
            "Type": "AWS::WAFRegional::XssMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-detect-xss"
                },
                "XssMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrXSSRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "mitigatexss",
                "Name": {
                    "Fn::Sub": "WAF-mitigate-xss"
                },
                "Predicates": [
                    {
                        "Type": "XssMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrXSSSet"
                        }
                    }
                ]
            }
        },
        "wafrPathsStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-rfi-lfi-traversal"
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "../",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "../",
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "../",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "../",
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "://",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "://",
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "://",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "://",
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrPathsRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "detectrfilfi",
                "Name": {
                    "Fn::Sub": "WAF-detect-rfi-lfi-traversal"
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrPathsStringSet"
                        }
                    }
                ]
            }
        },
        "wafrAdminUrlStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-admin-url"
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "STARTS_WITH",
                        "TargetString": "/admin",
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafrAdminRemoteAddrIpSet": {
            "Type": "AWS::WAFRegional::IPSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-admin-remote-ip"
                },
                "IPSetDescriptors": [
                    {
                        "Type": "IPV4",
                        "Value": "127.0.0.1/32"
                    }
                ]
            }
        },
        "wafrAdminAccessRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "detectadminaccess",
                "Name": {
                    "Fn::Sub": "WAF-detect-admin-access"
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrAdminUrlStringSet"
                        }
                    },
                    {
                        "Type": "IPMatch",
                        "Negated": true,
                        "DataId": {
                            "Ref": "wafrAdminRemoteAddrIpSet"
                        }
                    }
                ]
            }
        },
        "wafrSizeRestrictionSet": {
            "Type": "AWS::WAFRegional::SizeConstraintSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-size-restrictions"
                },
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": 512
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": 1024
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": 1048575
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": 4096
                    }
                ]
            }
        },
        "wafrSizeRestrictionRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "restrictsizes",
                "Name": {
                    "Fn::Sub": "WAF-restrict-sizes"
                },
                "Predicates": [
                    {
                        "Type": "SizeConstraint",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrSizeRestrictionSet"
                        }
                    }
                ]
            }
        },
        "wafrCSRFMethodStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-csrf-method"
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "METHOD"
                        },
                        "PositionalConstraint": "EXACTLY",
                        "TargetString": "post",
                        "TextTransformation": "LOWERCASE"
                    }
                ]
            }
        },
        "wafrCSRFTokenSizeConstraint": {
            "Type": "AWS::WAFRegional::SizeConstraintSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-csrf-token"
                },
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "x-csrf-token"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "EQ",
                        "Size": 36
                    }
                ]
            }
        },
        "wafrCSRFRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "enforcecsrf",
                "Name": {
                    "Fn::Sub": "WAF-enforce-csrf"
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrCSRFMethodStringSet"
                        }
                    },
                    {
                        "Type": "SizeConstraint",
                        "Negated": true,
                        "DataId": {
                            "Ref": "wafrCSRFTokenSizeConstraint"
                        }
                    }
                ]
            }
        },
        "wafrServerSideIncludeStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-ssi"
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "STARTS_WITH",
                        "TargetString": "/includes",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".cfg",
                        "TextTransformation": "LOWERCASE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".conf",
                        "TextTransformation": "LOWERCASE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".config",
                        "TextTransformation": "LOWERCASE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".ini",
                        "TextTransformation": "LOWERCASE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".log",
                        "TextTransformation": "LOWERCASE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".bak",
                        "TextTransformation": "LOWERCASE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": ".backup",
                        "TextTransformation": "LOWERCASE"
                    }
                ]
            }
        },
        "wafrServerSideIncludeRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "detectssi",
                "Name": {
                    "Fn::Sub": "WAF-detect-ssi"
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrServerSideIncludeStringSet"
                        }
                    }
                ]
            }
        },
        "wafrBlacklistIpSet": {
            "Type": "AWS::WAFRegional::IPSet",
            "Properties": {
                "Name": {
                    "Fn::Sub": "WAF-match-blacklisted-ips"
                },
                "IPSetDescriptors": [
                    {
                        "Type": "IPV4",
                        "Value": "192.168.1.1/32"
                    },
                    {
                        "Type": "IPV4",
                        "Value": "192.168.1.1/32"
                    },
                    {
                        "Type": "IPV4",
                        "Value": "169.254.0.0/16"
                    },
                    {
                        "Type": "IPV4",
                        "Value": "172.16.0.0/16"
                    },
                    {
                        "Type": "IPV4",
                        "Value": "127.0.0.1/32"
                    },
                    {
                        "Type": "IPV4",
                        "Value": "10.110.123.223/32"
                    }
                ]
            }
        },
        "wafrBlacklistIpRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Properties": {
                "MetricName": "blacklistedips",
                "Name": {
                    "Fn::Sub": "WAF-detect-blacklisted-ips"
                },
                "Predicates": [
                    {
                        "Type": "IPMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrBlacklistIpSet"
                        }
                    }
                ]
            }
        },
        "wafrOwaspACL": {
            "Type": "AWS::WAFRegional::WebACL",
            "Properties": {
                "MetricName": "owaspacl",
                "Name": {
                    "Fn::Sub": "WAF-owasp-acl"
                },
                "DefaultAction": {
                    "Type": "ALLOW"
                },
                "Rules": [
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 10,
                        "RuleId": {
                            "Ref": "wafrSizeRestrictionRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 20,
                        "RuleId": {
                            "Ref": "wafrBlacklistIpRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 30,
                        "RuleId": {
                            "Ref": "wafrAuthTokenRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 40,
                        "RuleId": {
                            "Ref": "wafrSQLiRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 50,
                        "RuleId": {
                            "Ref": "wafrXSSRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 60,
                        "RuleId": {
                            "Ref": "wafrPathsRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "ALLOW"
                        },
                        "Priority": 70,
                        "RuleId": {
                            "Ref": "wafrCSRFRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 80,
                        "RuleId": {
                            "Ref": "wafrServerSideIncludeRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "BLOCK"
                        },
                        "Priority": 90,
                        "RuleId": {
                            "Ref": "wafrAdminAccessRule"
                        }
                    }
                ]
            }
        },
        "MyWebACLAssociation": {
            "Type": "AWS::WAFRegional::WebACLAssociation",
            "DependsOn": "wafrOwaspACL",
            "Properties": {
                "WebACLId": {
                    "Ref": "wafrOwaspACL"
                },
                "ResourceArn": "${aws_lb.loadBalance.arn}"
            }
        }
    }
}
STACK
} 
