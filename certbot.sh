#!/bin/bash
set -x
read email-ID
read domainName
sudo apt-get update -y && apt-get install git -y 
git clone https://github.com/certbot/certbot.git
cd certbot/
#sudo ./certbot-auto --debug -v --email abc@gmail.com --server https://acme-v01.api.letsencrypt.org/directory certonly -d abc.com -d www.abc.com -d *.abc.com
sudo ./certbot-auto --debug -v --email ${email-ID} --server https://acme-v01.api.letsencrypt.org/directory certonly -d ${domainName}
