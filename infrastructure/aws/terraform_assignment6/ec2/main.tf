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
variable "dbuser"{	
	type=string
  default="dbuser"
}
variable "dbpassword"{	
	type=string
  default="Ubuntu123$"
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
  depends_on = [aws_iam_role_policy_attachment.EC2ServiceRole_CRUD_policy_attach]
  role = var.EC2ServiceRoleName
}

#CALLING S3 BUCKET MODULE
module "s3_bucket"{
  source = "../s3_bucket"
  bucketName = var.bucketName
  
}

# CREATING AWS EC2 INSTANCE
resource "aws_instance" "example" {
  ami = var.ami_id
  instance_type = "t2.micro"
  user_data = "${templatefile("script/db_details.sh",
                                    {
                                      domain = module.rds_instance.rds_endpoint,
                                      bucketName = module.s3_bucket.s3_bucketId,
                                      dbuser = var.dbuser,
                                      dbpassword = var.dbpassword
                                    })}"
  
  
  #"${data.template_file.db_details.rendered}"
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
  depends_on=[module.rds_instance, module.s3_bucket, aws_iam_instance_profile.ec2instanceprofile]
  key_name= "csye6225" 
  disable_api_termination="false"


  tags = {
    Name = "Web Server"
  }
  
}



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


