#!/bin/bash -xe
sudo /opt/tomcat/bin/./shutdown.sh

# cleanup log files
sudo rm -rf /opt/tomcat/logs/catalina*
sudo rm -rf /opt/tomcat/logs/*.log
sudo rm -rf /opt/tomcat/logs/*.txt