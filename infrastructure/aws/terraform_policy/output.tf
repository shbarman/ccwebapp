output EC2ServiceRoleName{
    value="${aws_iam_role.EC2ServiceRole.name}"
}

output CodeDeployServiceARN{
    value="${aws_iam_role.CodeDeployServiceRole.arn}"
}

