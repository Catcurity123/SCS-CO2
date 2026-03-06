#!/bin/bash
#
# This script is executed by the EC2 instance upon launch.
# It installs NGINX and creates a web page to display instance metadata.
#

# Update packages and install NGINX for Amazon Linux 2
yum update -y
amazon-linux-extras install nginx1 -y
# sudo yum install -y mysql
systemctl start nginx
systemctl enable nginx

# Get a security token for IMDSv2 (valid for 6 hours)
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`

# Create the HTML file for the web server's root
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>EC2 Instance Metadata</title>
</head>
<body>
    <div class="container">
        <h1>EC2 Instance Metadata (via IMDSv2)</h1>
        <p><strong>Instance ID:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)</p>
        <p><strong>Instance Type:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)</p>
        <p><strong>Availability Zone:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/placement/availability-zone)</p>
        <p><strong>Public IPv4:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
        <p><strong>AMI ID:</strong> $(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/ami-id)</p>
    </div>
</body>
</html>
EOF
