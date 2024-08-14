#!/bin/bash -xe

# Update and install necessary packages
apt-get update
apt-get install -y apache2 wget
sudo rm /var/www/html/index.html

# Download files
wget https://cl-sharedmedia.s3.amazonaws.com/sapro-iamrole-revocation/InstanceA/index.html -P /var/www/html
wget https://cl-sharedmedia.s3.amazonaws.com/sapro-iamrole-revocation/InstanceA/sophie.jpeg -P /var/www/html

# Adjust permissions
chown -R www-data:www-data /var/www
chmod -R 755 /var/www

# Enable and start Apache
systemctl enable apache2
systemctl start apache2

# Install CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb
apt-get install -f  # Install any dependencies that may be missing

# CWAgent Fix
mkdir -p /usr/share/collectd/
touch /usr/share/collectd/types.db
# CWAgent Fix End

# Configure and start CloudWatch Agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c ssm:${CloudWatchLinuxConfig} -s

# Send signal to CloudFormation
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackId} --resource EC2InstanceA --region ${AWS::Region}
