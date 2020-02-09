# Infrastructure

## wordpress_jedi.yaml
This is the Cloudformation template use to create, instantiate, populate and start the WordPress environment as defined by Project Jedi.  It is made up of the following components:

**Web Layer**
- Launch Config
- Autoscaling Group
- Autoscaling Group rules
- EC2 instance(s) running Amazon Linux 2
- Shared storage between web layer instances
- Shared storage mount targets for each subnet 
- Load balancer
- Target group
- DNS alias to Load balancer
- SSL cert attached to load balancer listener

**Database Layer**
- MySQL database in Amazon RDS

**Security**
- Web security group with ingress rules
- Storage security group with ingress rules
- Database security group with ingress rules

**Much focus has been on the Launch Configuration.  This is the code that runs on the server after initial creation.  This code will:**
- Install MySQL 8.0 client from Oracle
- Install PHP 7.3 from Remi
- install Apache and SNMP
- Update all packages to current
- Download and install latest Wordpress
- Modify Apache httpd.conf
- Modify Wordpress wp-config.php
- Create Wordpress .htaccess
- Create SNMPv3 user and enable SNMP service
- Start Apache

**There are some manual steps to run after the Cloudformation template has been started:**
  - There should be an email sent to cbadmin@caringbridge.org for the SSL certificate. You must click the link to accept the certificate from the email, otherwise the Cloudfront script will never have a status of CREATE_COMPLETE.
  - Go to a server created in the scaling group (http://10.10x.xx.xx). Enter the parameters for the wordpress environment. Otherwise the servers will not serve up any pages to customers.  Since the information is shared on the EFS volume, it    will work for all nodes in the cluster.
  - Update DNS for wpjedi.{environment}.caringbridge.org on the domain controller. This will allow easy access to Wordpress from a user's desktop.
  - Update LogicMonitor with the correct information for the monitored objects


## instantiate.sql

This script is called by Wordpress-Jedi.yaml when creating the EC2 instances (part of the Launch Config).  It is responsible for:
- Populating the Wordpress wp-config.php with real data
- Configuring Apache /etc/httpd/conf/httpd.conf with known good values
- Creating an .htaccess file in the Wordpress home directory

It uses variables passed to it from CloudFormation via /tmp/create-wp-config
