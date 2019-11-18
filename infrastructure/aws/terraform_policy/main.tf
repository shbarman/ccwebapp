variable "code_deploy_name"{
  description="ENTER NAME FOR CODE DEPLOY LIKE codedeploy.csyeshbarman.me"
  type=string
}
variable "lambda_bucket_name"{
  type=string
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_iam_policy" "circleci-ec2-ami" {
  name        = "circleci-ec2-ami"
  description = "A ec2 ami"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
      "Effect": "Allow",
      "Action" : [
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CopyImage",
        "ec2:CreateImage",
        "ec2:CreateKeypair",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSnapshot",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:DeleteKeyPair",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSnapshot",
        "ec2:DeleteVolume",
        "ec2:DeregisterImage",
        "ec2:DescribeImageAttribute",
        "ec2:DescribeImages",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeRegions",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSnapshots",
        "ec2:DescribeSubnets",
        "ec2:DescribeTags",
        "ec2:DescribeVolumes",
        "ec2:DetachVolume",
        "ec2:GetPasswordData",
        "ec2:ModifyImageAttribute",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifySnapshotAttribute",
        "ec2:RegisterImage",
        "ec2:RunInstances",
        "ec2:StopInstances",
        "ec2:TerminateInstances"
      ],
      "Resource" : "*"
  }]
}
EOF
}

resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name        = "CodeDeploy-EC2-S3"
  description = "A deploy policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": ["s3:List*",
                        "s3:Get*"],
            "Effect": "Allow",
            "Resource": ["arn:aws:s3:::${var.code_deploy_name}/*", "arn:aws:s3:::aws-codedeploy-us-east-2/*",
              "arn:aws:s3:::aws-codedeploy-us-east-1/*"]
        }
    ]
}
EOF
}

resource "aws_iam_policy" "CircleCI-Upload-To-S3" {
  name        = "CircleCI-Upload-To-S3"
  description = "A Upload policy"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["s3:PutObject","s3:GetObject", "s3:DeleteObject","s3:GetObjectAcl", "s3:GetObjectVersionAcl", "s3:ListBucket","s3:ListAllMyBuckets"],
            "Resource": ["arn:aws:s3:::${var.code_deploy_name}/*", "arn:aws:s3:::${var.lambda_bucket_name}/*" ]
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "circleci-policy-attach" {
  name       = "circleci-policy"
  users      = ["circleci"]
  policy_arn = "${aws_iam_policy.circleci-ec2-ami.arn}"
}

resource "aws_iam_policy_attachment" "circleci-upload-policy-attach" {
  name       = "circleci-upload-policy"
  users      = ["circleci"]
  policy_arn = "${aws_iam_policy.CircleCI-Upload-To-S3.arn}"
}



resource "aws_iam_role" "EC2ServiceRole" {
  name = "EC2ServiceRole"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "EC2ServiceRole"
  }
}


resource "aws_iam_role_policy_attachment" "EC2ServiceRole_cloudwatch_policy_attach" {
  role       = "${aws_iam_role.EC2ServiceRole.name}"
  depends_on = [aws_iam_role.EC2ServiceRole]
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}



resource "aws_iam_role_policy_attachment" "EC2ServiceRole_codeDeploy_policy_attach" {
  role       = "${aws_iam_role.EC2ServiceRole.name}"
  depends_on = [aws_iam_role.EC2ServiceRole]
  policy_arn = "${aws_iam_policy.CodeDeploy-EC2-S3.arn}"
}

resource "aws_iam_role" "CodeDeployServiceRole" {
  name = "CodeDeployServiceRole"
  path = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "CodeDeployServiceRole"
  }
}

# resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole_CRUD_policy_attach" {
#   role       = "${aws_iam_role.CodeDeployServiceRole.name}"
#   depends_on = [aws_iam_role.CodeDeployServiceRole]
#   policy_arn = "${aws_iam_policy.s3Bucket-CRUD-Policy.arn}"
# }


resource "aws_iam_role_policy_attachment" "CodeDeployServiceRole_codeDeploy_policy_attach" {
  role       = "${aws_iam_role.CodeDeployServiceRole.name}"
  depends_on = [aws_iam_role.CodeDeployServiceRole]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

