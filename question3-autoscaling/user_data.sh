#!/bin/bash
# ============================================================================
# Flantas AWS Assignment - Question 3: Auto Scaling Bootstrap Script
# Author: Aryan Vishwakarma
# Purpose: Configure EC2 instances in Auto Scaling Group
# This script runs on each instance launch to ensure consistent configuration
# ============================================================================

# System updates - Critical for security and stability
sudo apt update -y
sudo apt upgrade -y

# Install and configure Nginx web server
# Each ASG instance serves identical content for load distribution
sudo apt install nginx -y

# Remove default content
sudo rm -f /var/www/html/index.nginx-debian.html

# Create application webpage
# In production, this would typically pull from S3 or a deployment pipeline
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

# Apply configuration
sudo systemctl restart nginx

# Security: Restrict file system permissions
# Prevents unauthorized modification of web content
sudo chown -R root:root /var/www/html
sudo chmod -R 755 /var/www/html
