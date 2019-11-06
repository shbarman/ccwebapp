#!/bin/bash -xe
sudo /opt/tomcat/bin/./startup.sh
sudo systemctl start amazon-cloudwatch-agent.service
