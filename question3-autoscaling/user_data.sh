#!/bin/bash

# System updates
sudo apt update -y
sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y

# Remove default page
sudo rm -f /var/www/html/index.nginx-debian.html

# Create application page
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
  <title>Aryan Vishwakarma - Resume</title>
</head>
<body style="font-family: Arial; margin: 50px;">
  <h1>Hello, I'm <b>Aryan Vishwakarma</b></h1>
  <h2>Resume Website Hosted on EC2 + Nginx</h2>
  <p>This is a static website deployed as part of the Flantas AWS assignment.</p>
</body>
</html>
EOF

# Restart Nginx
sudo systemctl restart nginx

# Set directory permissions
sudo chown -R root:root /var/www/html
sudo chmod -R 755 /var/www/html
