mkdir ansible
echo "Installing Ansible"
sudo apt install nano dialog apt-utils -y 
sudo add-apt-repository ppa:ansible/ansible
sudo apt update
sudo apt install software-properties-common ansible whois -y
sudo apt install python3-argcomplete python3-netaddr -y
sudo activate-global-python-argcomplete3
sudo cp /etc/ansible/hosts  ~/ansible/hosts.bak
# Generate Ansible password
# Auto-Generate Strong Password for user, 21 characters long
pass=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&^*_'\' </dev/urandom | head -c 21 ; echo)
# let user know what password will be used
echo "The password is: "$pass
echo "Please write it down as it is not stored anywhere"
read -p "Hit any key to continue once you have the password" -n 1
echo ""
clear
# contninue with the script        

echo $pass | sudo tee /home/fliebing/ansible/playbooks/.pwd
ansible-vault encrypt ~/ansible/playbooks/kube/inventories/homelab/group_vars/all --vault-pass-file ~/ansible/playbooks/.pwd
ansible-vault encrypt ~/ansible/playbooks/kube/inventories/homelab/group_vars/ansible --vault-pass-file ~/ansible/playbooks/.pwd
ansible-vault encrypt ~/ansible/playbooks/kube/inventories/homelab/group_vars/db --vault-pass-file ~/ansible/playbooks/.pwd
ansible-vault encrypt ~/ansible/playbooks/kube/inventories/homelab/group_vars/kubecluster --vault-pass-file ~/ansible/playbooks/.pwd
sudo mv ~/ansible/playbooks/kube/library/ansible ~/.ssh/id_rsa
sudo mv ~/ansible/playbooks/kube/library/ansible.pub ~/.ssh/id_rsa.pub
chmod 400 ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa.pub
sudo chmod 755 /etc/ansible/
cat /home/fliebing/ansible/playbooks/kube/library/ansible.txt | sudo tee -a /etc/ansible/ansible.cfg
ssh-copy-id -i $HOME/.ssh/id_rsa.pub fliebing@kubemaster01
ssh-copy-id -i $HOME/.ssh/id_rsa.pub fliebing@kubemaster02
ssh-copy-id -i $HOME/.ssh/id_rsa.pub fliebing@kubemaster03
ssh-keyscan -H kubemaster01 >> ~/.ssh/known_hosts
ssh-keyscan -H kubemaster02 >> ~/.ssh/known_hosts
ssh-keyscan -H kubemaster03 >> ~/.ssh/known_hosts
ssh kubemaster03
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
exit
ssh kubemaster02
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
exit
sudo sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
ansible all -m apt -a "update_cache=yes upgrade=yes" -b
ansible k3s_secondary -m reboot


sudo update-ca-certificates --fresh
export SSL_CERT_DIR=/etc/ssl/certs