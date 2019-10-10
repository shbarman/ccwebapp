AWS BASH SCRIPTING FOR CLI

csye6225-aws-networking-setup.sh script file creates a VPC with resources like subnets, route tables, internet gateway

Too create VPC, open terminal use command bash csye6225-aws-networking-setup.sh VPC_NAME, AWS_REGION, VPC_CIDR_BLOCK, SUBNET_CIDR_BLOCK(the four paramters as command line arguments)

As each resource in VPC is completed successfully the messages are displayed.

csye6225-aws-networking-teardown.sh script file delete resources like subnets, route tables, internet gateway with reference to a particular VPC_ID provided through command line while running the script

Too delete VPC, open terminal use command bas csye6225-aws-networking-teardown.sh VPC_ID

Each resource in a VPC along with the VPC will be deleted one-by-one and terminal will prompt with success/failure message
