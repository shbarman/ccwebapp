#!/bin/sh
sudo touch /opt/tomcat/bin/setenv.sh
sudo chmod 777 /opt/tomcat/bin/setenv.sh
sudo echo "JAVA_OPTS=\"\$JAVA_OPTS"\" > /opt/tomcat/bin/setenv.sh
sudo echo "JAVA_OPTS=\"\$JAVA_OPTS -Ddomain=${domain}"\" >> /opt/tomcat/bin/setenv.sh
sudo echo "JAVA_OPTS=\"\$JAVA_OPTS -DbucketName=${bucketName}"\" >> /opt/tomcat/bin/setenv.sh
sudo echo "JAVA_OPTS=\"\$JAVA_OPTS -Ddbuser=${dbuser}"\" >> /opt/tomcat/bin/setenv.sh
sudo echo "JAVA_OPTS=\"\$JAVA_OPTS -Ddbpassword=${dbpassword}"\" >> /opt/tomcat/bin/setenv.sh
sudo /opt/tomcat/bin/./shutdown.sh
sudo /opt/tomcat/bin/./startup.sh