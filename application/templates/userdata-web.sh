#!/bin/bash
sudo su - root
yum -y update

yum -y install httpd
echo "ProxyPass /myapp http://${app_lb}:8080/myapp
ProxyPassReverse /myapp http://${app_lb}:8080/myapp" >> /etc/httpd/conf/httpd.conf

service httpd start
chkconfig httpd on
