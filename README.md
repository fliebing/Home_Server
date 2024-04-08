# 1) **About this code**

Every MD file in this folder will contain the expalanation to the code in the correponding folder.
This code is provided with no support, as this is documentation of my own lab projects.

# 2) **Security Information**
Please feel free to use the code for your purposes I am trying to keep the code as clean as possible while allowing the users to choose the passwords being used or generating them randomly and therefore eliminating the possibility that I or anyone else would be able to know the passwords/secrets for the new deployments. 

I am updating this code based on a Debian 12 and an Arch 2024.04.01 distribution, and will test with other builds in the future.

---

# 3) Change Control

Change log can be found in: [Changelog.md](Changelog.md)

> **_WARNING: Always examine scripts downloaded from the internet before running them locally!!_** > 

---
---
# 4) **What this project is about:**
    This project looks at tthe automation of the build of a Physical/virtual lab for Kubernetes along with the deployment of the basic workloads that I would use for a home environment. This can also be modified for use with any workload.
    Key features:
        I am testing an AI using an LLM and access to my documentation, will continue training the AI based on the issues I encounter until it is functional across several domains, curenlty it is used to help me in:
            1) Domotics
            2) Chatbot/writing tasks
---
## 4.a) **Milestones/components**
    For this project every component is tracked separately, as there may be updates and changes to the configurations that are required based on the use cases.

1) PXE boot capability

2) [Ansible](Ansible/ansible_setup.sh)  **CAREFUL:THIS IS A BASH SCRIPT**

3) Terraform

4) [K3s Manual install](K3s-cluster-setup.md) or [K3s Ansible](Ansible/kube/install_k3s.yaml)

---
## 4.b) **My LAB Environment**
The lab is a series of small separate mini-pcs. I have a mix of Lenovo (2x), Dell (2x) and Protectili (1x) mini PCs that host the virtual machines and containers. i also have a NAS device as well as a Mac M1 used for the AI system. (You can always deploy without the AI or use a Windows machine with an appropriate GPU, I have not tested on Linux with GPU. Not recommended to place it on a Virtual environment unless you can do PCI passthrough of the GPU, as performance is impacted heavily without this.)
    
I have decided to use Arch Linux as the base OS for everything in my Lab environment, this makes it easier to support, although you may want to use a different Linux Distro, adn this is ok. The exceptions to the Arch systems are the Firewall, running FreeBSD and the AI system that is running MacOS.

If there is anything I cannot build with Arch Linux, I will try to use FreeBSD or if not Debian. PXE build instructions contain the Debian netboot image as well, so any systems that will need this OS are covered. I will add the ther OS later if needed.

Overall the way this is built is all systems are connected to a switch in a separate network for my lab, this gives me a sandboxed environment that I can completely separate from the Internet and my other networks, Production and  Management for all testing to ensure that the functionality is there even if there is no Internet.

For ease of use, I will be utilizing my existing Terraform, Ansible and PXE boot solution in my management Network. This is since I currently have a server down and do no thave the spare cores to set all of this in the lab 

Simplified Network diagram:

                                                                      ┌───────────┐    
                                                              ┌───────┤ Terraform │    
                                                              │       └───────────┘
                                                              │    
                                                              │       ┌───────────┐    
                                            ┌─────────────────┴───┐   │    PXE    │    
                                    ┌───────┤   Management SW     ├───┤  ANSIBLE  │    
                                    │       └─────────────────────┘   └───────────┘    
                                    │                                                  
                 ┌──────────┐  ┌────┴─────┐  ┌─────────────────────┐    ┌──────────┐    
                 │ISP Router├──┤ Firewall ├──┤      LAB SWITCH     ├────┤ LOCAL AI │    
                 └──────────┘  └──────────┘  └──────┬─┬─┬─┬────────┘    └──────────┘    
                                                    │ │ │ │                                
                                                    │ │ │ │       ┌────────────────┐      
                          ┌───────────┐             │ │ │ └───────┤ Bare Metal K3s │        
                          │           │             │ │ │         └────────────────┘    
                          │    NAS    ├─────────────┘ │ │                                   
                          │           │               │ │         ┌────────────────┐       
                          │           │               │ └─────────┤ Bare Metal K3s │    
                          └───────────┘               │           └────────────────┘   
                                                      │                                   
                                                      │           ┌────────────────┐     
                                                      └───────────┼─Bare Metal K3s │       
                                                                  └────────────────┘

In order to make this deployment flow in a logical manner I suggest you deploy the systems out in this order:
1) Database server: You will need it for semaphore and other items to come.
    Arch Linux
    MariaDB
2) Ansible with semaphore: Will help you deploy all the rest of the servers in the build, but needs a database
    Debian Linux - 
        Semaphore is officially released as an RPM, DEB and for FreeBSD only. Since I want to use my database so I can integrate Ansible with other Infrastructure as code projects, and don't want to use snap or docker, I am running an LXC container dedicated to Ansible.
    Ansible
    Semaphore
3) Webserver: First one built with Ansible, used to test deploy scripts in Semaphore. Good test as this is a simple server.
    Arch Linux
    NginX -
        This will start by hosting my PXE boot files so I can use HTTP instead of TFTP to make the transfers faster and more reliable. It will host other items as project progresses.
4) PXE Capability:  Milestone REACHED! Now we are able to PXE boot our servers and have Ansible finish the deployments. Required all previous servers to be deployed.
    Freebsd
    OPNSENSE Firewall -
        Configs vary depending on your deployment (baremetal vs virtualized, amount of NICs, VLANs needed, etc.) Only providing instructions for PXE portion of the setup, assuming you have a working firewall config.

---
# 5) **Build Instructions**

## 5.a) **Database Server**
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



## 5.b) **Ansible**
Notes:
1. Ansible deployments are very simple, you can use the turnkey ansible from Proxmox or install ansible using the [ansible_setup.sh](Ansible/ansible_setup.sh) script
2. After the Ansible install, you need to copy the playbooks you will use into the Ansible 

Install Ansible and Semaphore

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


## 5.c) **WEB Server**
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


## 5.d) **PXE**

CAREFUL! The webroot in the PXE configuration here may change based on the deployment of the webserver. I recently changed this to ARCH and using ANGIE instead of NginX, I will change the locations of the files accordingly.

Please note that since this is a Firewall, we will NOT be using Ansible to 

Notes:
1. This guide works with BIOS as we use gpxelinux.0 but it can be adapted for UEFI boot if needed. (Currently I will leave it as is, since the PXE booting is working with all my lab devices)
    
2. This guide for PXE works on OPNSENSE Firewalls to enable PXE from there. You may have a different Firewall that may not provide this option. When I did not have OPNSENSE I used FOG as the PXE boot and image deployment solution.

For instructions on how to get PXE to boot Arch Linux or Debian, see the [PXE_setup.md](PXE_setup.md)

    ### **PXE Booting Lenovo miniPc**  F12 while booting up to get to the Boot sequence selector.
Choose Network Boot, this is the second option, just in case you do not have a monitor or KVM connected to the system

    ### **PXE Booting HP Elitedesk miniPc**  F12 while booting up to PXE boot directly
F10 = Bios setup

    ### **PXE Booting Mac Mini (Gen1)** 

