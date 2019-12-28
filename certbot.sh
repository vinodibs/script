#!/bin/bash
set -x
read email_ID
read domainName
sudo apt-get update -y && apt-get install git -y 
git clone https://github.com/certbot/certbot.git
cd certbot/
####acm-v2 ####
sudo ./certbot-auto --debug -v --email abc@gmail.com --server https://acme-v02.api.letsencrypt.org/directory certonly -d abc.com -d www.abc.com -d *.abc.com
####acm-v1 ####
#sudo ./certbot-auto --debug -v --email abc@gmail.com --server https://acme-v01.api.letsencrypt.org/directory certonly -d abc.com -d www.abc.com -d *.abc.com
sudo ./certbot-auto --debug -v --email ${email_ID} --server https://acme-v01.api.letsencrypt.org/directory certonly -d ${domainName}
