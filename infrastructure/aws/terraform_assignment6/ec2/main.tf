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
    "Parameters": {
        "stackPrefix": {
            "Type": "String",
            "Description": "The prefix to use when naming resources in this stack. Normally we would use the stack name, but since this template can be used as a resource in other stacks we want to keep the naming consistent. No symbols allowed.",
            "ConstraintDescription": "Alphanumeric characters only, maximum 10 characters",
            "AllowedPattern": "^[a-zA-z0-9]+$",
            "MaxLength": 10,
            "Default": "generic"
        },
        "stackScope": {
            "Type": "String",
            "Description": "You can deploy this stack at a regional level, for regional WAF targets like Application Load Balancers, or for global targets, such as Amazon CloudFront distributions.",
            "AllowedValues": [
                "Global",
                "Regional"
            ],
            "Default": "Regional"
        },
        "ruleAction": {
            "Type": "String",
            "Description": "The type of action you want to iplement for the rules in this set. Valid options are COUNT or BLOCK.",
            "AllowedValues": [
                "BLOCK",
                "COUNT"
            ],
            "Default": "BLOCK"
        },
        "includesPrefix": {
            "Type": "String",
            "Description": "This is the URI path prefix (starting with '/') that identifies any files in your webroot that are server-side included components, and should not be invoked directly via URL. These can be headers, footers, 3rd party server side libraries or components. You can add additional prefixes later directly in the set.",
            "Default": "/includes"
        },
        "adminUrlPrefix": {
            "Type": "String",
            "Description": "This is the URI path prefix (starting with '/') that identifies your administrative sub-site. You can add additional prefixes later directly in the set.",
            "Default": "/admin"
        },
        "adminRemoteCidr": {
            "Type": "String",
            "Description": "This is the IP address allowed to access your administrative interface. Use CIDR notation. You can add additional ones later directly in the set.",
            "Default": "127.0.0.1/32"
        },
        "maxExpectedURISize": {
            "Type": "Number",
            "Description": "Maximum number of bytes allowed in the URI component of the HTTP request. Generally the maximum possible value is determined by the server operating system (maps to file system paths), the web server software, or other middleware components. Choose a value that accomodates the largest URI segment you use in practice in your web application.",
            "Default": 512
        },
        "maxExpectedQueryStringSize": {
            "Type": "Number",
            "Description": "Maximum number of bytes allowed in the query string component of the HTTP request. Normally the  of query string parameters following the \"?\" in a URL is much larger than the URI , but still bounded by the  of the parameters your web application uses and their values.",
            "Default": 1024
        },
        "maxExpectedBodySize": {
            "Type": "Number",
            "Description": "Maximum number of bytes allowed in the body of the request. If you do not plan to allow large uploads, set it to the largest payload value that makes sense for your web application. Accepting unnecessarily large values can cause performance issues, if large payloads are used as an attack vector against your web application.",
            "Default": 1048576
        },
        "maxExpectedCookieSize": {
            "Type": "Number",
            "Description": "Maximum number of bytes allowed in the cookie header. The maximum size should be less than 4096, the size is determined by the amount of information your web application stores in cookies. If you only pass a session token via cookies, set the size to no larger than the serialized size of the session token and cookie metadata.",
            "Default": 4093
        },
        "csrfExpectedHeader": {
            "Type": "String",
            "Description": "The custom HTTP request header, where the CSRF token value is expected to be encountered",
            "Default": "x-csrf-token"
        },
        "csrfExpectedSize": {
            "Type": "Number",
            "Description": "The size in bytes of the CSRF token value. For example if it's a canonically formatted UUIDv4 value the expected size would be 36 bytes/ASCII characters",
            "Default": 36
        }
    },
    "Metadata": {
        "AWS::CloudFormation::Interface": {
            "ParameterGroups": [
                {
                    "Label": {
                        "default": "Resource Prefix"
                    },
                    "Parameters": [
                        "stackPrefix"
                    ]
                },
                {
                    "Label": {
                        "default": "WAF Implementation"
                    },
                    "Parameters": [
                        "stackScope",
                        "ruleAction"
                    ]
                },
                {
                    "Label": {
                        "default": "Generic HTTP Request Enforcement"
                    },
                    "Parameters": [
                        "maxExpectedURISize",
                        "maxExpectedQueryStringSize",
                        "maxExpectedBodySize",
                        "maxExpectedCookieSize"
                    ]
                },
                {
                    "Label": {
                        "default": "Administrative Interface"
                    },
                    "Parameters": [
                        "adminUrlPrefix",
                        "adminRemoteCidr"
                    ]
                },
                {
                    "Label": {
                        "default": "Cross-Site Request Forgery (CSRF)"
                    },
                    "Parameters": [
                        "csrfExpectedHeader",
                        "csrfExpectedSize"
                    ]
                },
                {
                    "Label": {
                        "default": "Application Specific"
                    },
                    "Parameters": [
                        "includesPrefix"
                    ]
                }
            ],
            "ParameterLabels": {
                "stackPrefix": {
                    "default": "Resource Name Prefix"
                },
                "stackScope": {
                    "default": "Apply to WAF"
                },
                "ruleAction": {
                    "default": "Rule Effect"
                },
                "includesPrefix": {
                    "default": "Server-side components URI prefix"
                },
                "adminUrlPrefix": {
                    "default": "URI prefix"
                },
                "adminRemoteCidr": {
                    "default": "Allowed IP source (CIDR)"
                },
                "maxExpectedURISize": {
                    "default": "Max. size of URI"
                },
                "maxExpectedQueryStringSize": {
                    "default": "Max. size of QUERY STRING"
                },
                "maxExpectedBodySize": {
                    "default": "Max. size of BODY"
                },
                "maxExpectedCookieSize": {
                    "default": "Max. size of COOKIE"
                },
                "csrfExpectedHeader": {
                    "default": "HTTP Request Header"
                },
                "csrfExpectedSize": {
                    "default": "Token Size"
                }
            }
        }
    },
    "Conditions": {
        "isRegional": {
            "Fn::Equals": [
                {
                    "Ref": "stackScope"
                },
                "Regional"
            ]
        },
        "isGlobal": {
            "Fn::Equals": [
                {
                    "Ref": "stackScope"
                },
                "Global"
            ]
        }
    },
    "Resources": {
        "wafrSQLiSet": {
            "Type": "AWS::WAFRegional::SqlInjectionMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-sqli"
                        ]
                    ]
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
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafgSQLiSet": {
            "Type": "AWS::WAF::SqlInjectionMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-sqli"
                        ]
                    ]
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
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrSQLiRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigatesqli"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigate-sqli"
                        ]
                    ]
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
        "wafgSQLiRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigatesqli"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigate-sqli"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "SqlInjectionMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgSQLiSet"
                        }
                    }
                ]
            }
        },
        "wafrAuthTokenStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-auth-tokens"
                        ]
                    ]
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
        "wafgAuthTokenStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-auth-tokens"
                        ]
                    ]
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
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "badauthtokens"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-bad-auth-tokens"
                        ]
                    ]
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
        "wafgAuthTokenRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "badauthtokens"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-bad-auth-tokens"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgAuthTokenStringSet"
                        }
                    }
                ]
            }
        },
        "wafrXSSSet": {
            "Type": "AWS::WAFRegional::XssMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-xss"
                        ]
                    ]
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
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafgXSSSet": {
            "Type": "AWS::WAF::XssMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-xss"
                        ]
                    ]
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
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "HTML_ENTITY_DECODE"
                    }
                ]
            }
        },
        "wafrXSSRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigatexss"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigate-xss"
                        ]
                    ]
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
        "wafgXSSRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigatexss"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "mitigate-xss"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "XssMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgXSSSet"
                        }
                    }
                ]
            }
        },
        "wafrPathsStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-rfi-lfi-traversal"
                        ]
                    ]
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
        "wafgPathsStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-rfi-lfi-traversal"
                        ]
                    ]
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
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectrfilfi"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-rfi-lfi-traversal"
                        ]
                    ]
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
        "wafgPathsRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectrfilfi"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-rfi-lfi-traversal"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgPathsStringSet"
                        }
                    }
                ]
            }
        },
        "wafrAdminUrlStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-admin-url"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "STARTS_WITH",
                        "TargetString": {
                            "Ref": "adminUrlPrefix"
                        },
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafgAdminUrlStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-admin-url"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "STARTS_WITH",
                        "TargetString": {
                            "Ref": "adminUrlPrefix"
                        },
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafrAdminRemoteAddrIpSet": {
            "Type": "AWS::WAFRegional::IPSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-admin-remote-ip"
                        ]
                    ]
                },
                "IPSetDescriptors": [
                    {
                        "Type": "IPV4",
                        "Value": {
                            "Ref": "adminRemoteCidr"
                        }
                    }
                ]
            }
        },
        "wafgAdminRemoteAddrIpSet": {
            "Type": "AWS::WAF::IPSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-admin-remote-ip"
                        ]
                    ]
                },
                "IPSetDescriptors": [
                    {
                        "Type": "IPV4",
                        "Value": {
                            "Ref": "adminRemoteCidr"
                        }
                    }
                ]
            }
        },
        "wafrAdminAccessRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectadminaccess"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-admin-access"
                        ]
                    ]
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
        "wafgAdminAccessRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectadminaccess"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-admin-access"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgAdminUrlStringSet"
                        }
                    },
                    {
                        "Type": "IPMatch",
                        "Negated": true,
                        "DataId": {
                            "Ref": "wafgAdminRemoteAddrIpSet"
                        }
                    }
                ]
            }
        },
        "wafrPHPInsecureQSStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-php-insecure-var-refs"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "_SERVER[",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "_ENV[",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "auto_prepend_file=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "auto_append_file=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "allow_url_include=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "disable_functions=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "open_basedir=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "safe_mode=",
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafgPHPInsecureQSStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-php-insecure-var-refs"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "_SERVER[",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "_ENV[",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "auto_prepend_file=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "auto_append_file=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "allow_url_include=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "disable_functions=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "open_basedir=",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "PositionalConstraint": "CONTAINS",
                        "TargetString": "safe_mode=",
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafrPHPInsecureURIStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-php-insecure-uri"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": "php",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": "/",
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafgPHPInsecureURIStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-php-insecure-uri"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": "php",
                        "TextTransformation": "URL_DECODE"
                    },
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "ENDS_WITH",
                        "TargetString": "/",
                        "TextTransformation": "URL_DECODE"
                    }
                ]
            }
        },
        "wafrPHPInsecureRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectphpinsecure"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-php-insecure"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrPHPInsecureQSStringSet"
                        }
                    },
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafrPHPInsecureURIStringSet"
                        }
                    }
                ]
            }
        },
        "wafgPHPInsecureRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectphpinsecure"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-php-insecure"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgPHPInsecureQSStringSet"
                        }
                    },
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgPHPInsecureURIStringSet"
                        }
                    }
                ]
            }
        },
        "wafrSizeRestrictionSet": {
            "Type": "AWS::WAFRegional::SizeConstraintSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "size-restrictions"
                        ]
                    ]
                },
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedURISize"
                        }
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedQueryStringSize"
                        }
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedBodySize"
                        }
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedCookieSize"
                        }
                    }
                ]
            }
        },
        "wafgSizeRestrictionSet": {
            "Type": "AWS::WAF::SizeConstraintSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "size-restrictions"
                        ]
                    ]
                },
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedURISize"
                        }
                    },
                    {
                        "FieldToMatch": {
                            "Type": "QUERY_STRING"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedQueryStringSize"
                        }
                    },
                    {
                        "FieldToMatch": {
                            "Type": "BODY"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedBodySize"
                        }
                    },
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": "cookie"
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "GT",
                        "Size": {
                            "Ref": "maxExpectedCookieSize"
                        }
                    }
                ]
            }
        },
        "wafrSizeRestrictionRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "restrictsizes"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "restrict-sizes"
                        ]
                    ]
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
        "wafgSizeRestrictionRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "restrictsizes"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "restrict-sizes"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "SizeConstraint",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgSizeRestrictionSet"
                        }
                    }
                ]
            }
        },
        "wafrCSRFMethodStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-csrf-method"
                        ]
                    ]
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
        "wafgCSRFMethodStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-csrf-method"
                        ]
                    ]
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
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-csrf-token"
                        ]
                    ]
                },
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": {
                                "Ref": "csrfExpectedHeader"
                            }
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "EQ",
                        "Size": {
                            "Ref": "csrfExpectedSize"
                        }
                    }
                ]
            }
        },
        "wafgCSRFTokenSizeConstraint": {
            "Type": "AWS::WAF::SizeConstraintSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-csrf-token"
                        ]
                    ]
                },
                "SizeConstraints": [
                    {
                        "FieldToMatch": {
                            "Type": "HEADER",
                            "Data": {
                                "Ref": "csrfExpectedHeader"
                            }
                        },
                        "TextTransformation": "NONE",
                        "ComparisonOperator": "EQ",
                        "Size": {
                            "Ref": "csrfExpectedSize"
                        }
                    }
                ]
            }
        },
        "wafrCSRFRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "enforcecsrf"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "enforce-csrf"
                        ]
                    ]
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
        "wafgCSRFRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "enforcecsrf"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "enforce-csrf"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgCSRFMethodStringSet"
                        }
                    },
                    {
                        "Type": "SizeConstraint",
                        "Negated": true,
                        "DataId": {
                            "Ref": "wafgCSRFTokenSizeConstraint"
                        }
                    }
                ]
            }
        },
        "wafrServerSideIncludeStringSet": {
            "Type": "AWS::WAFRegional::ByteMatchSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-ssi"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "STARTS_WITH",
                        "TargetString": {
                            "Ref": "includesPrefix"
                        },
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
        "wafgServerSideIncludeStringSet": {
            "Type": "AWS::WAF::ByteMatchSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-ssi"
                        ]
                    ]
                },
                "ByteMatchTuples": [
                    {
                        "FieldToMatch": {
                            "Type": "URI"
                        },
                        "PositionalConstraint": "STARTS_WITH",
                        "TargetString": {
                            "Ref": "includesPrefix"
                        },
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
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectssi"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-ssi"
                        ]
                    ]
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
        "wafgServerSideIncludeRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detectssi"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-ssi"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "ByteMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgServerSideIncludeStringSet"
                        }
                    }
                ]
            }
        },
        "wafrBlacklistIpSet": {
            "Type": "AWS::WAFRegional::IPSet",
            "Condition": "isRegional",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-blacklisted-ips"
                        ]
                    ]
                },
                "IPSetDescriptors": [
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
                    }
                ]
            }
        },
        "wafgBlacklistIpSet": {
            "Type": "AWS::WAF::IPSet",
            "Condition": "isGlobal",
            "Properties": {
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "match-blacklisted-ips"
                        ]
                    ]
                },
                "IPSetDescriptors": [
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
                    }
                ]
            }
        },
        "wafrBlacklistIpRule": {
            "Type": "AWS::WAFRegional::Rule",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "blacklistedips"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-blacklisted-ips"
                        ]
                    ]
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
        "wafgBlacklistIpRule": {
            "Type": "AWS::WAF::Rule",
            "Condition": "isGlobal",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "blacklistedips"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "detect-blacklisted-ips"
                        ]
                    ]
                },
                "Predicates": [
                    {
                        "Type": "IPMatch",
                        "Negated": false,
                        "DataId": {
                            "Ref": "wafgBlacklistIpSet"
                        }
                    }
                ]
            }
        },
        "wafrOwaspACL": {
            "Type": "AWS::WAFRegional::WebACL",
            "Condition": "isRegional",
            "Properties": {
                "MetricName": {
                    "Fn::Join": [
                        "",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "owaspacl"
                        ]
                    ]
                },
                "Name": {
                    "Fn::Join": [
                        "-",
                        [
                            {
                                "Ref": "stackPrefix"
                            },
                            "owasp-acl"
                        ]
                    ]
                },
                "DefaultAction": {
                    "Type": "ALLOW"
                },
                "Rules": [
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 10,
                        "RuleId": {
                            "Ref": "wafrSizeRestrictionRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 20,
                        "RuleId": {
                            "Ref": "wafrBlacklistIpRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 30,
                        "RuleId": {
                            "Ref": "wafrAuthTokenRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 40,
                        "RuleId": {
                            "Ref": "wafrSQLiRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 50,
                        "RuleId": {
                            "Ref": "wafrXSSRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 60,
                        "RuleId": {
                            "Ref": "wafrPathsRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 70,
                        "RuleId": {
                            "Ref": "wafrPHPInsecureRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": "ALLOW"
                        },
                        "Priority": 80,
                        "RuleId": {
                            "Ref": "wafrCSRFRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 90,
                        "RuleId": {
                            "Ref": "wafrServerSideIncludeRule"
                        }
                    },
                    {
                        "Action": {
                            "Type": {
                                "Ref": "ruleAction"
                            }
                        },
                        "Priority": 100,
                        "RuleId": {
                            "Ref": "wafrAdminAccessRule"
                        }
                    }
                ]
            }
        }
    },
    "Outputs": {
        "wafWebACL": {
            "Value": {
                "Ref": "wafrOwaspACL"
            }
        },
        "wafWebACLMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "owaspacl"
                    ]
                ]
            }
        },
        "wafSQLiRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrSQLiRule"
                    },
                    {
                        "Ref": "wafgSQLiRule"
                    }
                ]
            }
        },
        "wafSQLiRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "mitigatesqli"
                    ]
                ]
            }
        },
        "wafAuthTokenRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrAuthTokenRule"
                    },
                    {
                        "Ref": "wafgAuthTokenRule"
                    }
                ]
            }
        },
        "wafAuthTokenRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "badauthtokens"
                    ]
                ]
            }
        },
        "wafXSSRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrXSSRule"
                    },
                    {
                        "Ref": "wafgXSSRule"
                    }
                ]
            }
        },
        "wafXSSRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "mitigatexss"
                    ]
                ]
            }
        },
        "wafPathsRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrPathsRule"
                    },
                    {
                        "Ref": "wafgPathsRule"
                    }
                ]
            }
        },
        "wafPathsRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "detectrfilfi"
                    ]
                ]
            }
        },
        "wafPHPMisconfigRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrPHPInsecureRule"
                    },
                    {
                        "Ref": "wafgPHPInsecureRule"
                    }
                ]
            }
        },
        "wafPHPMisconfigRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "detectphpinsecure"
                    ]
                ]
            }
        },
        "wafAdminAccessRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrAdminAccessRule"
                    },
                    {
                        "Ref": "wafgAdminAccessRule"
                    }
                ]
            }
        },
        "wafAdminAccessRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "detectadminaccess"
                    ]
                ]
            }
        },
        "wafCSRFRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrCSRFRule"
                    },
                    {
                        "Ref": "wafgCSRFRule"
                    }
                ]
            }
        },
        "wafCSRFRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "enforcecsrf"
                    ]
                ]
            }
        },
        "wafSSIRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrServerSideIncludeRule"
                    },
                    {
                        "Ref": "wafgServerSideIncludeRule"
                    }
                ]
            }
        },
        "wafSSIRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "detectssi"
                    ]
                ]
            }
        },
        "wafBlacklistIpRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrBlacklistIpRule"
                    },
                    {
                        "Ref": "wafgBlacklistIpRule"
                    }
                ]
            }
        },
        "wafBlacklistIpRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "blacklistedips"
                    ]
                ]
            }
        },
        "wafSizeRestrictionRule": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrSizeRestrictionRule"
                    },
                    {
                        "Ref": "wafgSizeRestrictionRule"
                    }
                ]
            }
        },
        "wafSizeRestrictionRuleMetric": {
            "Value": {
                "Fn::Join": [
                    "",
                    [
                        {
                            "Ref": "stackPrefix"
                        },
                        "restrictsizes"
                    ]
                ]
            }
        },
        "wafAuthTokenBlacklist": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrAuthTokenStringSet"
                    },
                    {
                        "Ref": "wafgAuthTokenStringSet"
                    }
                ]
            }
        },
        "wafAdminAccessWhitelist": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrAdminRemoteAddrIpSet"
                    },
                    {
                        "Ref": "wafgAdminRemoteAddrIpSet"
                    }
                ]
            }
        },
        "wafIpBlacklist": {
            "Value": {
                "Fn::If": [
                    "isRegional",
                    {
                        "Ref": "wafrBlacklistIpSet"
                    },
                    {
                        "Ref": "wafgBlacklistIpSet"
                    }
                ]
            }
        }
      
        
    }
}

STACK
} 
# resource "aws_wafregional_web_acl_association" "WAF_ASSOCIATION" {
#   resource_arn = "${aws_lb.loadBalance.arn}"
#   web_acl_id   = v
# }