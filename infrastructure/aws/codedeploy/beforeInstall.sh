#!/bin/bash -xe
sudo /opt/tomcat/bin/./shutdown.sh
sudo systemctl stop amazon-cloudwatch-agent.service