#!/bin/bash
set -x
git clone https://github.com/certbot/certbot.git
cd certbot/
sudo ./certbot-auto --debug -v --server https://acme-v01.api.letsencrypt.org/directory certonly -d abc.com
