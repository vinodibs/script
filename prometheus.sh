#!/bin/bash
sudo apt-get update -y
set -x

# Create Users
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Prometheus Monitoring User" prometheus
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Node Exporter User" node_exporter
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Alertmanager User" alertmanager
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "Blackbox Exporter User" blackbox_exporter
sudo adduser --no-create-home --disabled-login --shell /bin/false --gecos "MySQL exporter user" mysql_exporter

# Create Directories
sudo mkdir /etc/prometheus
sudo mkdir /etc/alertmanager
sudo mkdir /etc/alertmanager/data
sudo mkdir /etc/alertmanager/template
sudo mkdir /etc/blackbox
sudo mkdir /var/lib/prometheus
sudo mkdir /etc/mysql_exporter

# Create Configureation Files
sudo touch /etc/prometheus/prometheus.yml
sudo touch /etc/alertmanager/alertmanager.yml
sudo touch /etc/blackbox/blackbox.yml
sudo touch /etc/mysql_exporter/.my.cnf

# Ownship Assign
sudo chown -R prometheus:prometheus /etc/prometheus
sudo chown -R alertmanager:alertmanager /etc/alertmanager
sudo chown -R blackbox_exporter:blackbox_exporter /etc/blackbox
sudo chown prometheus:prometheus /var/lib/prometheus
sudo chown -R mysql_exporter:mysql_exporter /etc/mysql_exporter

# Download Binaries
cd /tmp
wget https://raw.githubusercontent.com/vinodibs/package/master/alertmanager-0.12.0.linux-amd64.tar.gz
wget https://raw.githubusercontent.com/vinodibs/package/master/prometheus-2.0.0.linux-amd64.tar.gz
wget https://raw.githubusercontent.com/vinodibs/package/master/grafana_4.6.3_amd64.deb
wget https://raw.githubusercontent.com/vinodibs/package/master/node_exporter-0.15.2.linux-amd64.tar.gz
wget https://raw.githubusercontent.com/vinodibs/package/master/blackbox_exporter-0.11.0.linux-amd64.tar.gz
wget https://raw.githubusercontent.com/vinodibs/package/master/mysqld_exporter-0.10.0.linux-amd64.tar.gz

# Untar Binaries
tar xvzf prometheus-2.0.0.linux-amd64.tar.gz
tar xvzf alertmanager-0.12.0.linux-amd64.tar.gz
tar xvzf blackbox_exporter-0.11.0.linux-amd64.tar.gz
tar xvzf node_exporter-0.15.2.linux-amd64.tar.gz
tar xvzf mysqld_exporter-0.10.0.linux-amd64.tar.gz

# Copy Binaries to /usr/local/bin (and for main app copy libs...)
sudo cp prometheus-2.0.0.linux-amd64/prometheus /usr/local/bin/
sudo cp prometheus-2.0.0.linux-amd64/promtool /usr/local/bin/
sudo cp -vr prometheus-2.0.0.linux-amd64/consoles /etc/prometheus
sudo cp -vr prometheus-2.0.0.linux-amd64/console_libraries /etc/prometheus
sudo cp alertmanager-0.12.0.linux-amd64/alertmanager /usr/local/bin/
sudo cp alertmanager-0.12.0.linux-amd64/amtool /usr/local/bin/
sudo cp blackbox_exporter-0.11.0.linux-amd64/blackbox_exporter /usr/local/bin/
sudo cp node_exporter-0.15.2.linux-amd64/node_exporter /usr/local/bin/
sudo cp mysqld_exporter-0.10.0.linux-amd64/mysqld_exporter /usr/local/bin/

# Assing Ownership
sudo chown -R prometheus:prometheus /etc/prometheus/consoles
sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
sudo chown prometheus:prometheus /usr/local/bin/prometheus
sudo chown prometheus:prometheus /usr/local/bin/promtool
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
sudo chown blackbox_exporter:blackbox_exporter /usr/local/bin/blackbox_exporter
sudo chown mysql_exporter:mysql_exporter /usr/local/bin/mysqld_exporter

###########
cat >> /etc/prometheus/prometheus.yml <<-EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node_exporter'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9100']
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - http://localhost
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9115
  - job_name: 'mysql_exporter'
    scrape_interval: 5s
    static_configs:
      - targets:
        - localhost:9104	
EOF
	 
###########	 
cat >> /etc/blackbox/blackbox.yml <<-EOF
modules:
  http_2xx:
    prober: http
    timeout: 5s
    http:
      valid_http_versions: ["HTTP/1.1", "HTTP/2"]
      valid_status_codes: []  # Defaults to 2xx
      method: GET
EOF


###########
cat >> /etc/alertmanager/alertmanager.yml <<-EOF
global:
  smtp_smarthost: 'localhost:25'
  smtp_from: 'alertmanager@example.org'
  smtp_auth_username: 'alertmanager'
  smtp_auth_password: 'password'

# templates:
# - '/etc/alertmanager/template/*.tmpl'

route:
  repeat_interval: 3h 
  receiver: team-X-mails

receivers:
- name: 'team-X-mails'
  email_configs:
  - to: 'devops@impressico.co'
EOF

###########
cat >> /etc/mysql_exporter/.my.cnf <<-EOF
[client]
user=db_user
password=db_password
EOF

###########
cat >> /etc/systemd/system/prometheus.service <<-EOF
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

########### Node Exporter
cat >> /etc/systemd/system/node_exporter.service <<-EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

########### Blackbox Exporter
cat >> /etc/systemd/system/blackbox_exporter.service <<-EOF
[Unit]
Description=Prometheus blackbox exporter
After=network.target auditd.service

[Service]
User=blackbox_exporter
Group=blackbox_exporter
Type=simple
ExecStart=/usr/local/bin/blackbox_exporter --config.file=/etc/blackbox/blackbox.yml
Restart=on-failure

[Install]
WantedBy=default.target
EOF

########### Alertmanager
cat >> /etc/systemd/system/alertmanager.service <<-EOF
[Unit]
Description=Prometheus Alert Manager service
Wants=network-online.target
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
ExecStart=/usr/local/bin/alertmanager --config.file /etc/alertmanager/alertmanager.yml --storage.path /etc/alertmanager/data
Restart=always

[Install]
WantedBy=multi-user.target
EOF

########### MySql Exporter
cat >> /etc/systemd/system/mysql_exporter.service <<-EOF
[Unit]
Description=Prometheus MySQL Exporter
After=network.target

[Service]
User=mysql_exporter
Group=mysql_exporter
Type=simple
ExecStart=/usr/local/bin/mysqld_exporter \
    --config.my-cnf="/etc/mysql_exporter/.my.cnf"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

########## Grafana UI
sudo dpkg -i grafana_4.6.3_amd64.deb


########## Restart Application
sudo systemctl restart prometheus
sudo systemctl restart grafana-server
sudo systemctl restart alertmanager
sudo systemctl restart blackbox_exporter
sudo systemctl restart node_exporter
sudo systemctl start mysql_exporter

########## Enable Services
sudo systemctl enable prometheus
sudo systemctl enable grafana
sudo systemctl enable alertmanager
sudo systemctl enable blackbox_exporter
sudo systemctl enable node_exporter
sudo systemctl enable mysql_exporter
