#!/bin/bash

echo Put Here, your Website Name alongwith ip add. with space  - Ex, site1.example.com   192.168.0.1 
read $website_name1

echo Put Here, your Another Website Name alongwith ip add. with space - Ex, site2.example.com   192.168.0.2 
read $website_name2

#### Debug Enabling ####
set -x

#### Generate Self Sign Certificate ####
sudo mkdir -p /etc/pki/tls/certs
sudo chmod 755 /etc/pki/tls/certs
sudo apt-get install libssl1.0.0 -y

cd /etc/pki/tls/certs
export FQDN=`hostname -f`
echo -------------------
echo FQDN is $FQDN
echo -------------------

sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
-keyout $FQDN.key -out $FQDN.crt \
-subj "/C=US/ST=CA/L=SFO/O=myorg/CN=$FQDN"

cat $FQDN.crt $FQDN.key | sudo tee -a $FQDN.pem
openssl x509 -noout -subject -in /etc/pki/tls/certs/$FQDN.crt


##### Install HA Proxy , Load Balancer Server ####
sudo add-apt-repository ppa:vbernat/haproxy-1.8 -y
sudo apt-get update -y 
sudo apt-get install haproxy -y


#### Load Balancing Configuration ####
cat >> /etc/haproxy/haproxy.cfg <<-EOF

# Frontend HA_Proxy Service 

frontend HA-http
    bind *:80
    reqadd X-Forwarded-Proto:\ http
    default_backend web-backend


frontend HA-https
    bind *:443 ssl crt /etc/pki/tls/certs/$FQDN.pem
    reqadd X-Forwarded-Proto:\ https
    default_backend web-backend

# Backend Apache/ Nginx Service 

backend web-backend
    balance roundrobin
    option forwardfor
    redirect scheme https if !{ ssl_fc }
    server $website_name1:80 check
    server $website_name2:80 check

EOF

#### Config Test HA ####
#haproxy -c -f /etc/haproxy/haproxy.cfg

#### Restart & Enable rsyslog service ####
sudo systemctl restart haproxy
sudo systemctl enable haproxy

#### Install HA Logging ####
sudo apt-get install hatop -y

#### Enable HA Logging ####
sudo echo "local0.*    "-/var/log/haproxy_0.log" " >> /etc/rsyslog.conf
sudo echo "local1.*    "-/var/log/haproxy_1.log" " >> /etc/rsyslog.conf

#### Restart & Enable rsyslog service ####
sudo systemctl restart rsyslog
sudo systemctl enable rsyslog
