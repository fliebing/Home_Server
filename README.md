# 1) **About this code**

For Details please go to the Wiki.

---

# 2) Change Control

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
    a. Needed for the larger project
    b. Follow instructions [here](Instructions_4_Component_setup/Database.md)

2) Ansible with semaphore: Will help you deploy all the rest of the servers in the build, but needs a database
    a.  Ansible deployments are very simple, you can use the turnkey ansible from Proxmox or install ansible using the [ansible_setup.sh](Bash_Scripts/Ansible/ansible_setup.sh) script
    b. After the Ansible install, you need to copy the playbooks you will use into the Ansible or install Semaphore following [this](Instructions_4_Component_setup/Semaphore.md)

3) Webserver: First one built with Ansible, used to test deploy scripts in Semaphore. Good test as this is a simple server.
    a. The webroot is: /usr/share/nginx/html/index.html
    b. Config file is located at: /etc/nginx/nginx.conf

4) PXE Capability:  Milestone REACHED! Now we are able to PXE boot our servers and have Ansible finish the deployments. 

CAREFUL! The webroot in the PXE configuration here may change based on the deployment of the webserver. I recently changed this to ARCH and using ANGIE instead of NginX, I will change the locations of the files accordingly.

Please note that since this is a Firewall, we will NOT be able to use Ansible in the same way to manage it. Will need to load new libraries.

Notes:
1. This guide works with BIOS as we use gpxelinux.0 but it can be adapted for UEFI boot if needed. (Currently I will leave it as is, since the PXE booting is working with all my lab devices)
    
2. This guide for PXE works on OPNSENSE Firewalls to enable PXE from there. You may have a different Firewall that may not provide this option. When I did not have OPNSENSE I used FOG as the PXE boot and image deployment solution.

For instructions on how to get PXE to boot Arch Linux or Debian, see the [PXE_setup.md](Instructions_4_Component_setup/PXE_setup.md)

    ### **PXE Booting Lenovo miniPc**  F12 while booting up to get to the Boot sequence selector.
Choose Network Boot, this is the second option, just in case you do not have a monitor or KVM connected to the system

    ### **PXE Booting HP Elitedesk miniPc**  F12 while booting up to PXE boot directly
F10 = Bios setup

    ### **PXE Booting Mac Mini (Gen1)** 

---




