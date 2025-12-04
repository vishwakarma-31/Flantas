#!/bin/bash
# ============================================================================
# Flantas AWS Assignment - Question 2: EC2 Bootstrap Script
# Author: Aryan Vishwakarma
# Purpose: Install and configure Nginx with security hardening
# This script runs automatically when the EC2 instance launches
# ============================================================================

# Update package lists and upgrade all installed packages
# This ensures all security patches are applied
sudo apt update -y
sudo apt upgrade -y

# Install Nginx web server
# Nginx chosen for its lightweight footprint and excellent performance
sudo apt install nginx -y

# Remove default Nginx welcome page to replace with custom content
sudo rm -f /var/www/html/index.nginx-debian.html

# Create custom resume website HTML page
# Using heredoc for clean multi-line content generation
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

# Restart Nginx to apply configuration changes
sudo systemctl restart nginx

# Security Hardening: Set proper directory permissions
# Ensures only root can modify website files, preventing unauthorized changes
sudo chown -R root:root /var/www/html
sudo chmod -R 755 /var/www/html
