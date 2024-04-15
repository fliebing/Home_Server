## Overview:
This is MariaDB server deployed on Arch

### ARCH/MARIADB setup:
After deploying Arch on the system, if using Proxmox, you can deploy an LXC container with archlinux-base_20230608 template and minimal standard params OR you can use the [Arch Install.sh](Bash_Scripts/Homeserver_install/Arch_install.sh) script on a Bare metal or VM after booting with the ARCH CD or USB.

### You will need to log into the system and run with root priviledges:
1) rm -rf /etc/pacman.d/gnupg/*
2) pacman-key --init
3) pacman-key --populate archlinux
4) pacman -Sy archlinux-keyring && pacman -Syu
5) pacman -Syu openssh --noconfirm
6) systemctl restart sshd
7) systemctl enable sshd
8) pacman -Sy python-pip
Note: I will add this to the scipt as well as in Ansible so that you no longer need to do this in every Arch server. For now you will see this block in all Arch servers.
We need pythn installed for Ansible to work properly, so please make sure it is installed.
If error in pacman, then ``` pacman-key --refresh-keys  ```  (NOTE: THIS TAKES AN EXTREEEEEEEEEEEEEMELY LOOONG TIME!!!)

### Installing MariaDB:
1) pacman -Syu mariadb --noconfirm
2) mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
3) systemctl start mariadb.service
4) systemctl enable mariadb.service
5) mariadb-secure-installation
Note: For this item make sure that you answer NO to using only Unix sockets, this is to enable only localhost access, we will need to have this listen to incoming connections, as we will use this database for the larger setup, not only semaphore.
For our usecase, all other items should be answered with the defaults.

### Basic configuration to support Semaphore
Create the semaphore DB and Add a user
mysql -u root -p
    CREATE DATABASE semaphore_db;
    GRANT ALL PRIVILEGES ON semaphore_db.* TO {YOUR semaphore_username}@{IP OF ANSIBLE SYSTEM} IDENTIFIED BY '{YOUR SUPER SECRET PASSWORD}';
    FLUSH PRIVILEGES;
    exit
