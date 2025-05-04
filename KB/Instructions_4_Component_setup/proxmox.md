To install vms and containers from ansible we will require some pre-work:

## Prerequisites
1. Install Ansible: Ensure you have Ansible installed on your machine.
1. Install proxmoxer: You need the proxmoxer Python library, which can be installed with pip:

pip install proxmoxer 
Ansible Inventory: Create an inventory file (e.g., inventory.ini) to define your Proxmox server.
Example Inventory File (inventory.ini)

[proxmox]
your-proxmox-ip ansible_user=your-username ansible_password=your-password ansible_connection=local
Ansible Playbook (proxmox_debian.yml)



---
- name: Create a Debian VM and Arch LXC on Proxmox
  hosts: proxmox
  gather_facts: no
  tasks:
    - name: Create a Debian VM
      proxmox_kvm:
        api_user: "{{ ansible_user }}@pam"  # Adjust if using a different realm
        api_password: "{{ ansible_password }}"
        api_host: "{{ inventory_hostname }}"
        vmid: 100  # Unique VM ID
        name: "DebianServer"
        cores: 2
        memory: 2048
        net0: "virtio,bridge=vmbr0"  # Adjust as needed
        disk:
          - size: 10G
            storage: local-lvm  # Change based on your storage setup
            type: scsi
        os_type: l26  # Linux (Debian)
        clone: "template-debian"  # Name of your Debian template
        state: present
        boot: cdn  # Boot from CD/DVD and network
      register: debian_vm

    - name: Wait for the Debian VM to start
      wait_for:
        timeout: 300
        delay: 10
        port: 22
        state: started
      when: debian_vm is defined

    - name: Configure Debian VM (e.g., install packages)
      ansible.builtin.shell: |
        sshpass -p 'password' ssh -o StrictHostKeyChecking=no admin@{{ debian_vm.instance.ip }} "apt-get update && apt-get install -y apache2"
      delegate_to: localhost
      when: debian_vm is defined

    - name: Create an Arch Linux LXC container
      proxmox_lxc:
        api_user: "{{ ansible_user }}@pam"  # Adjust if using a different realm
        api_password: "{{ ansible_password }}"
        api_host: "{{ inventory_hostname }}"
        vmid: 101  # Unique VM ID for the container
        name: "ArchContainer"
        cores: 1
        memory: 1024
        net0: "name=eth0,bridge=vmbr0,ip=dhcp"  # DHCP for the container
        rootfs:
          - size: 8G
            storage: local-lvm  # Change based on your storage setup
        ostemplate: "local:vztmpl/archlinux-2023.10.01-x86_64.tar.gz"  # Path to your Arch template
        state: present
      register: arch_container

    - name: Wait for the Arch container to start
      wait_for:
        timeout: 300
        delay: 10
        port: 22
        state: started
      when: arch_container is defined

    - name: Configure Arch LXC container (e.g., install packages)
      ansible.builtin.shell: |
        sshpass -p 'password' ssh -o StrictHostKeyChecking=no root@{{ arch_container.instance.ip }} "pacman -Sy --noconfirm && pacman -S --noconfirm apache"
      delegate_to: localhost
      when: arch_container is defined





# playbook_proxmox.yml
- name: Create VMs or Containers in Proxmox
  hosts: localhost
  tasks:
    - name: Create Debian VM
      proxmox_kvm:
        api_user: "root@pam"
        api_password: "your_password"
        api_host: "proxmox_host"
        node: "proxmox_node"
        vmid: 100
        memory: 2048
        cores: 2
        net0: "virtio,bridge=vmbr0"
        ostype: "l26"
        storage: "local-lvm"
        image: "debian.iso"
        state: present

    - name: Create Arch VM
      proxmox_kvm:
        api_user: "root@pam"
        api_password: "your_password"
        api_host: "proxmox_host"
        node: "proxmox_node"
        vmid: 101
        memory: 2048
        cores: 2
        net0: "virtio,bridge=vmbr0"
        ostype: "l26"
        storage: "local-lvm"
        image: "arch.iso"
        state: present

    - name: Create FreeBSD VM
      proxmox_kvm:
        api_user: "root@pam"
        api_password: "your_password"
        api_host: "proxmox_host"
        node: "proxmox_node"
        vmid: 102
        memory: 2048
        cores: 2
        net0: "virtio,bridge=vmbr0"
        ostype: "freebsd"
        storage: "local-lvm"
        image: "freebsd.iso"
        state: present