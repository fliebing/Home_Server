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
        4) [K3s Manual install](K3s-cluster-setup.md) or [K3s Ansible](Ansible/kube/install_k3s.yaml)
---
# **My LAB Environment**
    The lab is a series of small separate mini-pcs. I have a mix of Lenovo, Dell and Protectili mini PCs that host the virtual machines and containers. 
    
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
In order to make this deployment flow in a logical manner I suggest you build the systems out in this order:
    1) Database server
    2) Ansible with semaphore
    2) Webserver

# **Ansible**
Notes:
    1. Ansible deployments are very simple, you can use the turnkey ansible from Proxmox or install ansible using the [ansible_setup.sh](Ansible/ansible_setup.sh) script
    2. After the Ansible install, you need to copy the playbooks you will use into the Ansible 

# **WEB Server**

# **PXE**
Notes:
    1. This guide works with BIOS as we use gpxelinux.0 but it can be adapted for UEFI boot if needed. (Currently I will leave it as is, since the PXE booting is working with all my lab devices)
    2. This guide for PXE works on OPNSENSE Firewalls to enable PXE from there. You may have a different Firewall that may not provide this option. When I did not have OPNSENSE I used FOG as the PXE boot and image deployment solution.

For instructions on how to get PXE to boot Arch Linux or Debian, see the [PXE_setup.md](PXE_setup.md)

## **PXE Booting Lenovo miniPc**  F12 while booting up to get to the Boot sequence selector.
Choose Network Boot, this is the second option, just in case you do not have a monitor or KVM connected to the system

## **PXE Booting HP Elitedesk miniPc**  F12 while booting up to PXE boot directly
F10 = Bios setup

## **PXE Booting Mac Mini (Gen1)** 

