## Overview:
This is an Angie Web server deployed on Arch

### ARCH/ANGIE setup:
After deploying Arch on the system, you can use the [Arch Install.sh](Bash_Scripts/Homeserver_install/Arch_install.sh) 

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

### Installing Nginx: (Angie would be the Replacement for NginX as our web server if you want to install from AUR)
1) pacman -Sy nginx
2) systemctl start nginx.service
3) systemctl enable nginx.service

### TESTING:
    Use a browser and go to http://{IP of WEB SERVER}

The webroot is: /usr/share/nginx/html/index.html
Config file is located at: /etc/nginx/nginx.conf