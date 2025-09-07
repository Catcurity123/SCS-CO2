#!/bin/bash
set -e

# Output all logs to user-data.log, console, and system logger
exec > >(tee /var/log/user-data.log | logger -t user-data-extra -s 2>/dev/console) 2>&1

echo "=== Installing prerequisites ==="
apt update -y
apt upgrade -y
apt install -y nginx python3 unzip wget curl gnupg2 ca-certificates apt-transport-https

echo "=== Configuring NGINX to log request bodies ==="
cat << 'EOF' > /etc/nginx/conf.d/log_request_body.conf
# Ensure the request body is read into $request_body
client_body_buffer_size 16k;
client_max_body_size    1m;
client_body_in_single_buffer on;

# Define a format that includes the request body
log_format with_body '$remote_addr - $remote_user [$time_local] '
                     '"$request" $status $body_bytes_sent '
                     '"$http_referer" "$http_user_agent" '
                     'REQUEST_BODY: "$request_body"';

# Apply this format to the access log
access_log  /var/log/nginx/access_with_body.log  with_body;
EOF

echo "=== Testing and reloading NGINX ==="
nginx -t
systemctl enable --now nginx

echo "=== Installing Docker ==="
curl -fsSL https://get.docker.com | sh
systemctl enable --now docker

echo "=== Running Juice Shop container ==="
docker pull bkimminich/juice-shop:latest
docker run -d --name juice-shop --restart=always -p 3000:3000 bkimminich/juice-shop:latest

echo "=== Configuring NGINX reverse proxy ==="
cat <<'EOF' > /etc/nginx/sites-available/juice-shop
server {
    listen 80;
    server_name _;

    # Log incoming requests (with body) and proxy to Juice Shop
    access_log  /var/log/nginx/access_with_body.log  with_body;

    location /juice-shop/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300;
        proxy_send_timeout 300;
    }

    # Optional rewrite for /juice-shop without trailing slash
    location = /juice-shop {
        return 301 /juice-shop/;
    }

    # Default root
    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF

ln -sf /etc/nginx/sites-available/juice-shop /etc/nginx/sites-enabled/juice-shop
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

echo "=== Creating EC2 Dashboard page ==="
TOKEN=$(curl -sX PUT "http://169.254.169.254/latest/api/token" \
    -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)

cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>EC2 Instance Dashboard</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    .container { max-width: 800px; }
    .juice-shop-link {
      background: #ff6b35;
      color: white;
      padding: 15px 30px;
      text-decoration: none;
      border-radius: 5px;
      display: inline-block;
      margin: 20px 0;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>EC2 Instance Dashboard</h1>
    <a href="/juice-shop/" class="juice-shop-link">🧃 Access OWASP Juice Shop</a>
    <h2>Instance Metadata (via IMDSv2)</h2>
    <ul>
      <li><strong>Instance ID:</strong> $(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)</li>
      <li><strong>Instance Type:</strong> $(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-type)</li>
      <li><strong>Availability Zone:</strong> $(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)</li>
      <li><strong>Public IPv4:</strong> $(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)</li>
      <li><strong>AMI ID:</strong> $(curl -sH "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/ami-id)</li>
    </ul>
  </div>
</body>
</html>
EOF

echo "=== Installing CloudWatch Agent ==="
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb || true
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c ssm:${ssm_cloudwatch_config} -s || true

echo "=== Initialization complete: Juice Shop available at http://<EC2_PUBLIC_IP>/juice-shop/ ==="
