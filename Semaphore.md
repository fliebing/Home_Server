## Overview
Steps to install Ansible and Semaphore on a Debian system


### Installing Ansible:
install ansible using the [ansible_setup.sh](Ansible/ansible_setup.sh) script

### Installing Semaphore:
apt-get update
apt-get upgrade -y
wget https://github.com/semaphoreui/semaphore/releases/download/v2.9.64/semaphore_2.9.64_linux_amd64.deb
apt install ./semaphore_2.9.64_linux_amd64.deb
semaphore setup

NOTE: this will give you the following prompts:
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