#!/bin/bash -xe
cd /opt/tomcat/bin
sudo ./startup.sh
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl  -a fetch-config  -m ec2  -c file:/opt/cloudwatch-config.json  -s