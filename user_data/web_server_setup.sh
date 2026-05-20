#!/bin/bash -xe

sudo yum update -y

sudo yum install -y httpd

sudo systemctl enable httpd
sudo systemctl start httpd

echo "Web Server OK - $(hostname)" | sudo tee /var/www/html/index.html