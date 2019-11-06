#!/bin/bash -xe
cd /opt/tomcat/bin
sudo ./shutdown.sh

# cleanup log files
sudo rm -rf /opt/tomcat/logs/catalina*
sudo rm -rf /opt/tomcat/logs/*.log
sudo rm -rf /opt/tomcat/logs/*.txt