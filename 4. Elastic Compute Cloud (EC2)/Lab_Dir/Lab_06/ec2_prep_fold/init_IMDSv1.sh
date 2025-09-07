#!/bin/bash
set -e

# Output all log
exec > >(tee /var/log/user-data.log | logger -t user-data-extra -s 2>/dev/console) 2>&1

# 1. Update packages and install NGINX and Python3
apt update -y
apt upgrade -y
apt install -y nginx python3 unzip wget curl gnupg2 software-properties-common git build-essential awscli

systemctl start nginx
systemctl enable nginx

# 2. Create the HTML page displaying EC2 metadata using IMDSv1
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>EC2 Metadata</title>
</head>
<body>
  <h1>EC2 Instance Metadata (via IMDSv1)</h1>
  <ul>
    <li><strong>Instance ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-id)</li>
    <li><strong>Instance Type:</strong> $(curl -s http://169.254.169.254/latest/meta-data/instance-type)</li>
    <li><strong>Availability Zone:</strong> $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</li>
    <li><strong>Public IPv4:</strong> $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</li>
    <li><strong>AMI ID:</strong> $(curl -s http://169.254.169.254/latest/meta-data/ami-id)</li>
  </ul>
</body>
</html>
EOF

# 3. Configure CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# 4. Use CloudWatch config from SSM
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
-a fetch-config \
-m ec2 \
-c ssm:${ssm_cloudwatch_config} -s
