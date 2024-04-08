# **About this code**

Every MD file in this folder will contain the expalanation to the code in the correponding folder.
This code is provided with no support, as this is documentation of my own lab projects.

# **Security Information**
Please feel free to use the code for your purposes I am trying to keep the code as clean as possible while allowing the users to choose the passwords being used or generating them randomly and therefore eliminating the possibility that I or anyone else would be able to know the passwords/secrets for the new deployments. 

I am updating this code based on a Debian 10 distribution, and will test with other builds in the future.

---

# [Change Control] (Changelog.md)
> **_WARNING: Always examine scripts downloaded from the internet before running them locally!!_** > 

---
---
# **What this project is about**
    This project looks at tthe automation of the build of a Physical/virtual lab for Kubernetes along with the deployment of the basic workloads that I would use for a home environment. This can also be modified for use with any workload.
    Key features:
        I am testing an AI using an LLM and access to my documentation, will continue training the AI based on the issues I encounter until it is functional across several domains, curenlty it is used to help me in:
            1) Domotics
            2) Chatbot/writing tasks
---
# **Components needed**
    For this project every component is tracked separately, as there may be updates and changes to the configurations that are required based on the use cases.
    Please click on the 
        1) PXE boot capability
        2) [Ansible](Ansible/ansible_setup.sh)  **CAREFUL:THIS IS A BASH SCRIPT**
        3) Terraform
        4) [K3s ansible scripts](K3s-cluster-setup.md)
---
# **My LAB Environment**
    The lab is a series of small separate mini-pcs. I have a mix of Lenovo, Dell and Protectili mini PCs that host the virtual machines and containers. 
    Overall the way this is built is all systems are connected to a switch in a separate network for my lab, this gives me a sandoxed environment that I can completely separate from the Internet and my other networks, Production and  Management for all testing to ensure that the functionality is there even if there is no Internet.

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
 

# **PXE/Ansible**
Notes:
    1. This guide works with BIOS as we use pxelinux.0 but it can be adapted fairly easily for UEFI boot.
    2. This guide for PXE works on OPNSENSE Firewalls to enable PXE from there. You may have a different Firewall that may not provide this option. When I did not have OPNSENSE I used FOG as the PXE boot and image deployment solution.

## Overview:

PXE servers have 2 parts:

TFTP server to serve the bootloader and other files necessary for network booting.
DHCP configuration to respond to PXE requests with info including where to find the TFTP server and the bootloader file to start the network booting process.

### TFTP setup:

1. Install the tftp plugin in OPNSense

        1. Go to System > Firmware > Plugins. 
        2. Search for os-tftp. 
        3. Click on the + sign at the end of the row to install it.

You will get a message:

 ``` The root folder for transfering files is /usr/local/tftp. ```

Once the WebUI refreshes entry appears in Services > TFTP > General where the service can be enabled or disabled.

SSH into opnsense. Press 8 for Shell.

1. Make the directory we will use for the TFTP boot files:

```
mkdir -p /usr/local/tftp/pxelinux.cfg
```

2. Create the config file for pxelinux at /usr/local/tftp/pxelinux.cfg/default containing the following:
```
touch /usr/local/tftp/pxelinux.cfg/default
    tee -a /usr/local/tftp/pxelinux.cfg/default > /dev/null <<EOF
DEFAULT vesamenu.c32
PROMPT 0
MENU TITLE PXE Boot Menu (Main)

LABEL bsd-oses
   MENU LABEL BSD Operating Systems
   KERNEL vesamenu.c32
   APPEND pxelinux.cfg/bsd

EOF

touch /usr/local/tftp/pxelinux.cfg/bsd
    tee -a /usr/local/tftp/pxelinux.cfg/bsd > /dev/null <<EOF
MENU TITLE PXE Boot Menu (BSD)

LABEL main-menu
   MENU LABEL Main Menu
   KERNEL vesamenu.c32
   APPEND pxelinux.cfg/default
LABEL fbsd-pxe-install
   MENU LABEL Install FreeBSD 12.2 (PXE)
   MENU DEFAULT
   KERNEL memdisk
   INITRD http://192.168.5.5:8081/pxe/bsd/fbsd/amd64/12.2-RELEASE/mfsbsd.iso
   APPEND iso raw

EOF
```

3. Add pxelinux boot files to the TFTP root dir.

```
cd /tmp

pkg fetch -y syslinux
mkdir -p /tmp/syslinux
tar -C /tmp/syslinux -xvf /var/cache/pkg/syslinux-6.03.pkg

cp /tmp/syslinux/usr/local/share/syslinux/bios/core/lpxelinux.0 /usr/local/tftp/pxelinux.0
cp /tmp/syslinux/usr/local/share/syslinux/bios/com32/elflink/ldlinux/ldlinux.c32 /usr/local/tftp/
cp /tmp/syslinux/usr/local/share/syslinux/bios/com32/menu/vesamenu.c32 /usr/local/tftp/
cp /tmp/syslinux/usr/local/share/syslinux/bios/com32/lib/libcom32.c32 /usr/local/tftp/
cp /tmp/syslinux/usr/local/share/syslinux/bios/com32/libutil/libutil.c32 /usr/local/tftp/
cp /tmp/syslinux/usr/local/share/syslinux/bios/com32/modules/pxechn.c32 /usr/local/tftp/
cp /tmp/syslinux/usr/local/share/syslinux/bios/memdisk/memdisk /usr/local/tftp/

rm -r /tmp/syslinux

```
4. Add the ISO files to a web server (we could use the TFTP, but it is better to use a web server to host the files, as it is much faster)

```
 cd /usr/local/tftp
 curl -O http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/pxelinux.0
 curl -O http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/ldlinux.c32
```

5. OPNsense configuration

Navigate to Services > DHCPv4 > [LAN]

Expand Enable network booting.

Set next-server IP:        192.168.1.1  # the TFTP server, aka our OPNsense device's IP
Set default bios filename: pxelinux.0   # pxelinux.0 is the bootloader that works with bios.
Note: Ignore the TFTP server section, leave it disabled.


### Testing

In your local terminal, you can test if the tftp server is up and working correctly.

tftp 192.168.1.1
> get pxelinux.0 # transfer from server to local machine
[ctrl+d to exit]
file pxelinux.0 # display file metadata
If you receive a time-out or if the pxelinux.0 that was downloaded is empty, then check your TFTP configuration again. If it downloaded successfully, then all you have remaining is the OPNsense configuration!





