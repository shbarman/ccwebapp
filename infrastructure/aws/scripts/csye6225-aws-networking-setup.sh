#!/bin/bash

#variables used in script:

arguments=$@


if [ -z "$arguments" ]
then
	echo "----VPC NAME WAS NOT PROVIDED"
	exit 1
fi

params=($arguments)

vpcName=${params[0]}
vpcCidrBlock=${params[1]}
awsRegion=${params[2]}
subnetCidrBlock1=${params[3]}
subnetCidrBlock2=${params[4]}
subnetCidrBlock3=${params[5]}



echo "Creating VPC..."
echo $vpcName

#create vpc with cidr block /16
awsVPC_response=$(aws --region $awsRegion ec2 create-vpc --cidr-block "$vpcCidrBlock" --no-amazon-provided-ipv6-cidr-block --instance-tenancy default --output json)
vpcId=$(echo -e "$awsVPC_response" |  /usr/bin/jq '.Vpc.VpcId' | tr -d '"')
$(aws --region $awsRegion ec2 create-tags --resources "$vpcId" --tags Key=Name,Value="$vpcName")
echo $awsVPC_response
echo "---VPC CREATED----"
$(aws --region $awsRegion ec2 modify-vpc-attribute --vpc-id "$vpcId" --enable-dns-hostname)
$(aws --region $awsRegion ec2 modify-vpc-attribute --vpc-id "$vpcId" --enable-dns-support)


#Creating subnets with subnet cidr block

awsSubnet1_response=$(aws --region $awsRegion ec2 create-subnet --vpc-id "$vpcId" --cidr-block "$subnetCidrBlock1")

subnet1Id=$(echo -e "$awsSubnet1_response" |  /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $awsSubnet1_response
$(aws --region $awsRegion ec2 create-tags --resources "$subnet1Id" --tags Key=Name,Value="Subnet1")
echo "----SUBNET 1 CREATED----"


awsSubnet2_response=$(aws --region $awsRegion ec2 create-subnet --vpc-id "$vpcId" --cidr-block "$subnetCidrBlock2")

subnet2Id=$(echo -e "$awsSubnet2_response" |  /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $awsSubnet2_response
$(aws --region $awsRegion ec2 create-tags --resources "$subnet2Id" --tags Key=Name,Value="Subnet2")
echo "----SUBNET 2 CREATED----"


awsSubnet3_response=$(aws --region $awsRegion ec2 create-subnet --vpc-id "$vpcId" --cidr-block "$subnetCidrBlock3")

subnet3Id=$(echo -e "$awsSubnet3_response" |  /usr/bin/jq '.Subnet.SubnetId' | tr -d '"')
echo $awsSubnet3_response
$(aws --region $awsRegion ec2 create-tags --resources "$subnet3Id" --tags Key=Name,Value="Subnet3")
echo "----SUBNET 3 CREATED----"



#Add Gateway
gateway_response=$(aws --region $awsRegion ec2 create-internet-gateway --output json)
gatewayId=$(echo -e "$gateway_response" |  /usr/bin/jq '.InternetGateway.InternetGatewayId' | tr -d '"')
echo "-----GATEWAY CREATED----"


#Attaching gateway to VPC
attach_response=$(aws --region $awsRegion ec2 attach-internet-gateway --internet-gateway-id "$gatewayId" --vpc-id "$vpcId")

echo "-----GATEWAY ATTACHED----"

#create route table for vpc
route_table_response=$(aws --region $awsRegion ec2 create-route-table --vpc-id "$vpcId" --output json)
routeTableId=$(echo -e "$route_table_response" |  /usr/bin/jq '.RouteTable.RouteTableId' | tr -d '"')
#name the route table

aws --region $awsRegion ec2 create-tags --resources "$routeTableId" --tags Key=Name,Value="routeTable"
echo "-----ROUTE TABLE CREATED----"

#add route to subnet
response1=$(aws --region $awsRegion ec2 associate-route-table --subnet-id "$subnet1Id" --route-table-id "$routeTableId")
response2=$(aws --region $awsRegion ec2 associate-route-table --subnet-id "$subnet2Id" --route-table-id "$routeTableId")
response3=$(aws --region $awsRegion ec2 associate-route-table --subnet-id "$subnet3Id" --route-table-id "$routeTableId")
echo "----ROUTE ADDED TO SUBNET----"


#add route for the internet gateway
route_response=$(aws --region $awsRegion ec2 create-route --route-table-id "$routeTableId" --destination-cidr-block 0.0.0.0/0 --gateway-id "$gatewayId")
echo "---PUBLIC ROUTE FOR INTERNET CREATED----"






















