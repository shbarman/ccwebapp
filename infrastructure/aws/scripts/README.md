
VPC using CLI
1. Create a Virtual Private CLoud (VPC)
2. Create 3 subnets according to the requirements in the VPC with each in different availability zones
3. Create a Internet Gateway
4. Attach the Internet Gateway to VPC
5. Create a Public Route-Table and attach all the 3 subnets to the Route-Table
6. Create a public Route in the Public Route-Table with Destination Cidr BLock of 0.0.0.0/0 and connect to internet gateway as well.


AWS CLI SETUP
1. Install AWS CLI
2. Run aws configure command and enter all the credentials.
3. Enter dev and prod credentials and configuration




Creation Steps
1. csye6225-aws-networking-setup.sh script file creates a VPC with resources like subnets, route tables, internet gateway
2. Too create VPC, open terminal use command bash csye6225-aws-networking-setup.sh VPC_NAME, AWS_REGION, VPC_CIDR_BLOCK, SUBNET_CIDR_BLOCK(the four paramters as command line arguments)
3. As each resource in VPC is completed successfully the messages are displayed.

Teardown Steps
1. csye6225-aws-networking-teardown.sh script file delete resources like subnets, route tables, internet gateway with reference to a particular VPC_ID provided through command line while running the script

2. Too delete VPC, open terminal use command bas csye6225-aws-networking-teardown.sh VPC_ID AWS_REGION

3. Each resource in a VPC along with the VPC will be deleted one-by-one and terminal will prompt with success/failure message
