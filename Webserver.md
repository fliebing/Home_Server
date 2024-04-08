## Overview:
This is an Angie Web server deployed on Arch

### ARCH/ANGIE setup:
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

### Installing Angie: (Replacement for NginX as our web server)
1) pacman -Sy angie
2) systemctl start angie.service
3) systemctl enable angie.service

### TESTING:
    Use a browser and go to http://{IP of WEB SERVER}

The webroot is: /usr/share/nginx/html/index.html
Config file is located at: /etc/nginx/nginx.conf