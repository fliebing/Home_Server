## Overview
Steps to install Ansible and Semaphore on a Debian system


### Installing Ansible:
install ansible using the [ansible_setup.sh](Bash_Scripts/Ansible/ansible_setup.sh) script

### Installing Semaphore:
```
apt-get update
apt-get upgrade -y
apt-get install locales-all
dpkg-reconfigure locales
apt install python3 git curl wget software-properties-common bash-completion
apt-add-repository ppa:ansible/ansible
apt install -y ansible
mkdir /etc/ansible
chmod 755 /etc/ansible/
```
Make sure you place the id_rsa key in the .ssh folder and then
```
chmod 400 ~/.ssh/id_rsa
```
Then edit the bashrc file
```
tee -a ~/.bashrc > /dev/null <<EOF
if [ -f /usr/share/bash-completion/bash_completion ]; then
. /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
. /etc/bash_completion
fi
EOF

source ~/.bashrc
```
Finally download the semaphore files and install
```
wget https://github.com/semaphoreui/semaphore/releases/download/v2.9.64/semaphore_2.9.64_linux_amd64.deb
apt install ./semaphore_2.9.64_linux_amd64.deb
mkdir -p /etc/semaphore
cd /etc/semaphore
semaphore setup
```

NOTE: this will give you the following prompts:
```
Hello! You will now be guided through a setup to:

1. Set up configuration for a MySQL/MariaDB database
2. Set up a path for your playbooks (auto-created)
3. Run database Migrations
4. Set up initial semaphore user & password

What database to use:
   1 - MySQL
   2 - BoltDB
   3 - PostgreSQL
 (default 1): 1

db Hostname (default 127.0.0.1:3306): {DATABASE SERVER IP}:3306

db User (default root): {YOUR semaphore_username}

db Password: {YOUR SUPER SECRET PASSWORD}

db Name (default semaphore): semaphore_db

Playbook path (default /tmp/semaphore): /opt/semaphore

Public URL (optional, example: https://example.com/semaphore): 

Enable email alerts? (yes/no) (default no): 

Enable telegram alerts? (yes/no) (default no): 

Enable slack alerts? (yes/no) (default no): 

Enable Rocket.Chat alerts? (yes/no) (default no): 

Enable Microsoft Team Channel alerts? (yes/no) (default no): 

Enable LDAP authentication? (yes/no) (default no): 

Config output directory (default /root): 
```
Then do the following:
```
touch /etc/systemd/system/semaphore.service
  tee -a /etc/systemd/system/semaphore.service > /dev/null <<EOF
[Unit]
Description=Semaphore Ansible
Documentation=https://github.com/ansible-semaphore/semaphore
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
ExecReload=/bin/kill -HUP $MAINPID
ExecStart=/usr/bin/semaphore service --config=/etc/semaphore/config.json
SyslogIdentifier=semaphore
Restart=always

[Install]
WantedBy=multi-user.target

EOF
```
systemctl daemon-reload
systemctl start semaphore
systemctl enable semaphore