# terraform-aws-example
Terraform configs to create a simple VPC for a traditional Java web application using a Tomcat Server sitting behind an Apache Web Server.

**Note** 
AWS may charge for some of these resources (ie NAT Gateways, Elastic IPs, multiple EC2 instances). 

## Further configuration example

The following tasks can be easily automated with something like Chef (https://www.chef.io/) since none of your work would carry over to new instances. You may do this manually to test your resources before adding a more complex provisioning process.

### Web Server

Apache is installed through a User Data script as part of the web resource launch config. It also forwards any requests to /myapp to the Tomcat instances behind it.

Add an index.html on your web server's /var/www/html directory so that the load balancer will register this instance as healthy.

### App Server

The NAT Gateway is disabled by default to minimize cost, but you may enable it to see the internet from the private subnets. SSH into the app server instance and install Java and Tomcat. If you don't feel like paying, you may download these from the web instance in the public subnet and 

```
curl https://download.java.net/java/ga/jdk11/openjdk-11_linux-x64_bin.tar.gz > openjdk-11_linux-x64_bin.tar.gz
curl http://apache.mirrors.pair.com/tomcat/tomcat-9/v9.0.12/bin/apache-tomcat-9.0.12.zip > apache-tomcat-9.0.12.zip

tar -xzvf openjdk-11_linux-x64_bin.tar.gz
unzip apache-tomcat-9.0.12.zip

// tell apache where to find java 11
echo '
#!/bin/bash
JAVA_HOME=/home/ec2-user/jdk-11
' > apache-tomcat-9.0.12/bin/setenv.sh

chmod -R 755 apache-tomcat-9.0.12/bin/
apache-tomcat-9.0.12/bin/startup.sh
```

Add another index.html on apache-tomcat-9.0.12/webapps/myapp if you don't want to see Tomcat's default error page as part of your test.

### Test

If everything worked you should be able to see your web server's index.html when you visit http://${your_public_load_balancer} and your app server's index.html when you visit http://${your_public_load_balancer}/myapp
