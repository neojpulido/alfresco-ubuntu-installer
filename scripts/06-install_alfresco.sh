#!/bin/bash

set -e

echo "Install unzip command"
sudo apt -y install unzip

echo "Create support folders and configuration in Tomcat"
mkdir -p /home/root/tomcat/shared/classes && mkdir -p /home/root/tomcat/shared/lib
sed -i 's|^shared.loader=$|shared.loader=${catalina.base}/shared/classes,${catalina.base}/shared/lib/*.jar|' /home/root/tomcat/conf/catalina.properties

echo "Unzip Alfresco ZIP Distribution File"
mkdir /tmp/alfresco
unzip downloads/alfresco-content-services-community-distribution-23.2.1.zip -d /tmp/alfresco

echo "Copy JDBC driver"
cp /tmp/alfresco/web-server/lib/postgresql-42.6.0.jar /home/root/tomcat/shared/lib/

echo "Configure JAR Addons deployment"
mkdir -p /home/root/modules/platform && mkdir -p /home/root/modules/share && mkdir -p /home/root/tomcat/conf/Catalina/localhost
cp /tmp/alfresco/web-server/conf/Catalina/localhost/* /home/root/tomcat/conf/Catalina/localhost/

echo "Install Web Applications"
cp /tmp/alfresco/web-server/webapps/* /home/root/tomcat/webapps/

echo "Apply configuration"
cp -r /tmp/alfresco/web-server/shared/classes/* /home/root/tomcat/shared/classes/
mkdir /home/root/keystore && cp -r /tmp/alfresco/keystore/* /home/root/keystore/
mkdir /home/root/alf_data
cat <<EOL | tee /home/root/tomcat/shared/classes/alfresco-global.properties
#
# Custom content and index data location
#
dir.root=/home/root/alf_data
dir.keystore=/home/root/keystore/

#
# Database connection properties
#
db.username=alfresco
db.password=alfresco
db.driver=org.postgresql.Driver
db.url=jdbc:postgresql://localhost:5432/alfresco

#
# Solr Configuration
#
solr.secureComms=secret
solr.sharedSecret=secret
solr.host=localhost
solr.port=8983
index.subsystem.name=solr6

# 
# Transform Configuration
#
localTransform.core-aio.url=http://localhost:8090/

#
# Events Configuration
#
messaging.broker.url=failover:(nio://localhost:61616)?timeout=3000&jms.useCompression=true

#
# URL Generation Parameters
#-------------
alfresco.context=alfresco
alfresco.host=localhost
alfresco.port=8080
alfresco.protocol=http
share.context=share
share.host=localhost
share.port=8080
share.protocol=http
EOL

echo "Apply AMPs"
mkdir /home/root/amps && cp -r /tmp/alfresco/amps/* /home/root/amps/
mkdir /home/root/bin && cp -r /tmp/alfresco/bin/* /home/root/bin/
java -jar /home/root/bin/alfresco-mmt.jar install /home/root/amps /home/root/tomcat/webapps/alfresco.war -directory
java -jar /home/root/bin/alfresco-mmt.jar list /home/root/tomcat/webapps/alfresco.war

echo "Modify alfresco and share logs directory"
mkdir /home/root/tomcat/webapps/alfresco && unzip /home/root/tomcat/webapps/alfresco.war -d /home/root/tomcat/webapps/alfresco
mkdir /home/root/tomcat/webapps/share && unzip /home/root/tomcat/webapps/share.war -d /home/root/tomcat/webapps/share
sed -i 's|^appender\.rolling\.fileName=alfresco\.log|appender.rolling.fileName=/home/root/tomcat/logs/alfresco.log|' /home/root/tomcat/webapps/alfresco/WEB-INF/classes/log4j2.properties
sed -i 's|^appender\.rolling\.fileName=share\.log|appender.rolling.fileName=/home/root/tomcat/logs/share.log|' /home/root/tomcat/webapps/share/WEB-INF/classes/log4j2.properties


echo "Alfresco has been configured"