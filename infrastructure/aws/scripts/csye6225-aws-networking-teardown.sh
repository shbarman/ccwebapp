
 
#!/bin/bash
echo "-----TEARDOWN NETWORK RESOURCES USING AWS CLI-----"

VPC_ID="$1";
AWS_REGION="$2";
if [ -z "$VPC_ID" ]
then
	echo "-----VPC ID IS NOT PROVIDED------"
	exit 0
fi

vpc=$(aws --region $AWS_REGION ec2 describe-vpcs --filters Name=vpc-id,Values="$VPC_ID" --output text)
if [ -z "$vpc" ]
then
	echo "-----$VPC_ID DOES NOT EXIST----"
	exit 0
fi

#Finding Route Table ID
route_table_id=$(aws --region $AWS_REGION ec2 describe-route-tables --filters Name=vpc-id,Values="$VPC_ID" Name=association.main,Values=false --query 'RouteTables[*].{RouteTableId:RouteTableId}' --output text)
status=$?
if [ $status -ne 0 ];
then
	echo "-----FINDING ERROR ROUTE TABLE ID----"
        exit $status
fi

#Finding Internet Gateway ID
internet_gateway_id=$(aws --region $AWS_REGION ec2 describe-internet-gateways --filters Name=attachment.vpc-id,Values="$VPC_ID" --query 'InternetGateways[*].{InternetGatewayId:InternetGatewayId}' --output text)
status=$?
if [ $status -ne 0 ];
then
        echo "-----FINDING ERROR FOR INTERNET GATEWAY ID----"
        exit $status
fi

#Deleting Subnets in the VPC
subnets=$(aws --region $AWS_REGION ec2 describe-subnets --filters Name=vpc-id,Values="$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
status=$?
if [ $status -ne 0 ]
then
       	echo "-----NO SUBNETS FOUND----"
    	exit $status
fi
for subnet_id in $subnets
do
    aws --region $AWS_REGION ec2 delete-subnet --subnet-id $subnet_id
	status=$?
	if [ $status -ne 0 ];
	then
        	echo "----DELETING ERROR FOR SUBNET $subnet_id----"
        	exit $status
	fi
	echo "----DELETED SUBNET $subnet_id----"
done

#Deleting Route Table
aws --region $AWS_REGION ec2 delete-route-table --route-table-id $route_table_id
status=$?
if [ $status -ne 0 ];
then
        echo "----DELETING ERROR FOR ROUTE TABLE $route_table_id----"
        exit $status
fi
echo "-----DELETED ROUTE TABLE $route_table_id-----"

#Detaching Internet Gateway
aws --region $AWS_REGION ec2 detach-internet-gateway --internet-gateway-id $internet_gateway_id --vpc-id $VPC_ID
status=$?
if [ $status -ne 0 ];
then
        echo "-----DETACHING INTERNET GATEWAY $internet_gateway_id-----"
        exit $status
fi
echo "-----DETATCHED INTERNET GATEWAY $internet_gateway_id-----"

#Deleting Internet Gateway
aws --region $AWS_REGION ec2 delete-internet-gateway --internet-gateway-id $internet_gateway_id
status=$?
if [ $status -ne 0 ];
then
        echo "----DETACHING ERROR FOR $internet_gateway_id----"
        exit $status
fi
echo "----DELETED INTERNET GATEWAY $internet_gateway_id-----"

#Deleting VPC
aws --region $AWS_REGION ec2 delete-vpc --vpc-id $VPC_ID
status=$?
if [ $status -ne 0 ];
then
        echo "----DELETING ERROR $vpc-----"
        exit $status
fi
echo "-----DELETED VPC $VPC_ID---"
echo "----NETWORK TEARDOWN SUCCESSFULL----"
