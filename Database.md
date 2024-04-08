## Overview:
This is MariaDB server deployed on Arch

### ARCH/MARIADB setup:
After deploying Arch on the system, you can use the [Arch Install.sh](Homeserver_install/Arch_install.sh) 

### You will need to log into the system and run with root priviledges:
1) pacman -Sy archlinux-keyring
2) pacman-key --init
3) pacman-key --populate archlinux 
4) pacman-key --refresh-keys 
5) pacman -S openssh
6) systemctl restart sshd
7) systemctl enable sshd
Note: I will add this to the scipt as well as in Ansible so that you no longer need to do this in every Arch server. For now you will see this block in all Arch servers.

### Installing MariaDB:
1) pacman -S mariadb
2) mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
3) systemctl start mariadb.service
4) systemctl enable mariadb.service
5) mariadb-secure-installation
Note: For this item make sure that you answer NO to using only Unix sockets, this is to enable only localhost access, we will need to have this listen to incoming connections, as we will use this database fro the larger setup, not only semaphore.
For our usecase, all other itens should be answered with the defaults.

### Basic configuration to support Semaphore
Create the semaphore DB and Add a user
mysql -u root -p
    CREATE DATABASE semaphore_db;
    GRANT ALL PRIVILEGES ON semaphore_db.* TO {YOUR semaphore_username}@{IP OF ANSIBLE SYSTEM} IDENTIFIED BY '{YOUR SUPER SECRET PASSWORD}';
    FLUSH PRIVILEGES;
    exit
