#! /bin/bash

# Shell script to install apache/mysql/php/wordpress into an EC2 instance of Amazon AMI Linux.
# Step 1: Create an AWS EC2 instance
# Step 2: ssh in like: ssh -v -i wordpress.pem ec2-user@ec2-54-185-74-0.us-west-2.compute.amazonaws.com
# Step 3: Run this as root/superuser, do sudo su

echo "Shell script to install apache/mysql/php/wordpress into an EC2 instance of Amazon AMI Linux."
echo "Please run as root, if you're not, choose N now and enter 'sudo su' before running the script."
echo "Run script? (y/n)"

read -e run
if [ "$run" == n ] ; then
echo “error...”
exit
else

# Installs the updates
yum yum update -y

# Install the lamp-mariadb10.2-php7.2 and php7.2
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2

# Install the Apache web server
yum install -y httpd

# Install MariaDB
yum -y install mariadb-server mariadb

# Start the Apache web server
systemctl start httpd

# Configure the Apache web server
systemctl enable httpd

# Add your user (in this case, ec2-user) to the apache group
usermod -a -G apache ec2-user

#Change the group ownership of /var/www and its contents to the apache group
chown -R ec2-user:apache /var/www

# Add group write permissions and set the group ID on future subdirectories
chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;

# Add group write permissions
find /var/www -type f -exec sudo chmod 0664 {} \;

# Start MariaDB
systemctl start mariadb.service
systemctl enable mariadb.service

#Set passwords for the MySQL root account
mysql_secure_installation

# Create a database named wordpress
mysqladmin -uroot create wordpress

# Secure database
# non interactive mysql_secure_installation with a little help from expect.

SECURE_MYSQL=$(expect -c "
 
set timeout 10
spawn mysql_secure_installation
 
expect \"Enter current password for root (enter for none):\"
send \"\r\"
 
expect \"Change the root password?\"
send \"y\r\"

expect \"New password:\"
send \"password\r\"

expect \"Re-enter new password:\"
send \"password\r\"

expect \"Remove anonymous users?\"
send \"y\r\"
 
expect \"Disallow root login remotely?\"
send \"y\r\"
 
expect \"Remove test database and access to it?\"
send \"y\r\"
 
expect \"Reload privilege tables now?\"
send \"y\r\"
 
expect eof
")

echo "$SECURE_MYSQL"


# Change directory to web root
cd /var/www/html

echo "WordPress installing. Please weight..."

# Download Wordpress
wget http://wordpress.org/latest.tar.gz

# Extract Wordpress
tar -xzvf latest.tar.gz

# Copy files to /var/www/html/
mv /var/www/html/wordpress/* /var/www/html/

# Create a WordPress config file 
mv wp-config-sample.php wp-config.php

#set database details with perl find and replace
sed -i "s/database_name_here/wordpress/g" /var/www/html/wp-config.php
sed -i "s/username_here/root/g" /var/www/html/wp-config.php
sed -i "s/password_here//g" /var/www/html/wp-config.php

#create uploads folder and set permissions
mkdir wp-content/uploads
chmod 777 wp-content/uploads

#remove wp file
rm /var/www/html/latest.tar.gz
rm -r /var/www/html/wordpress

echo "Ready, go to http://'your ec2 url' and enter the blog info to finish the installation."

fi