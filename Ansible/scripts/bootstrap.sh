#!/usr/bin/env bash
set -euo pipefail

# 1) Prompt for Proxmox API & Vault passwords once
read -sp "Proxmox API password for root@pam: " PVE_PASS; echo
read -sp "Ansible Vault master password: " VAULT_PASS; echo

# 2) Install all prerequisites
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  python3 python3-venv python3-pip git sshpass

# 3) Setup SSH key (to push into control01 later)
ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N ""
echo
echo "Bootstrap public key:"
cat /root/.ssh/id_rsa.pub
echo

# 4) Clone your private Git repo
REPO="git@github.com:yourorg/infra-automation.git"
DEST="/root/infra-automation"
git clone "$REPO" "$DEST"

# 5) Create & activate a venv, install Ansible & Proxmox API client
python3 -m venv /opt/ansible-venv
source /opt/ansible-venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install ansible proxmoxer

# 6) Copy playbooks & scripts into /etc/ansible
ANSIBLE_DIR="/etc/ansible"
rm -rf "$ANSIBLE_DIR"
mkdir -p "$ANSIBLE_DIR"{/inventories,/playbooks,/roles,/scripts}
cp -r "$DEST/Ansible/inventories" "$ANSIBLE_DIR/"
cp -r "$DEST/Ansible/playbooks"   "$ANSIBLE_DIR/playbooks/"
cp -r "$DEST/Ansible/roles"       "$ANSIBLE_DIR/roles/"
cp -r "$DEST/Ansible/scripts"     "$ANSIBLE_DIR/scripts/"

# 7) Encrypt Vault file with PVE creds
export VAULT_PASS
VAULT_FILE="$ANSIBLE_DIR/group_vars/all/vault.yml"
mkdir -p "$(dirname "$VAULT_FILE")"
cat > "$VAULT_FILE" <<EOF
proxmox_api_user: root@pam
proxmox_api_password: "${PVE_PASS}"
EOF
ansible-vault encrypt "$VAULT_FILE" \
  --vault-password-file=<(echo "$VAULT_PASS")

# 8) Generate inventory from BOM
python3 "$ANSIBLE_DIR/scripts/bom2inventory.py" \
  --bom "$ANSIBLE_DIR/inventories/BOM.json" \
  --out "$ANSIBLE_DIR/inventories/inventory.json"

# 9) Create MariaDB LXC first
python3 "$ANSIBLE_DIR/scripts/update_bom_id.py" \
  "$ANSIBLE_DIR/inventories/BOM.json" lxc ct-central-db-mariadb

ansible-playbook -i "$ANSIBLE_DIR/inventories/inventory.json" \
  "$ANSIBLE_DIR/playbooks/proxmox/create-lxc.yml" \
  --extra-vars "component_ref=ct-central-db-mariadb" \
  --vault-password-file=<(echo "$VAULT_PASS")

# 10) Rebuild inventory (it now has the new LXC’s ID)
python3 "$ANSIBLE_DIR/scripts/bom2inventory.py" \
  --bom "$ANSIBLE_DIR/inventories/BOM.json" \
  --out "$ANSIBLE_DIR/inventories/inventory.json"

# 11) Create vm-control-01 next
python3 "$ANSIBLE_DIR/scripts/update_bom_id.py" \
  "$ANSIBLE_DIR/inventories/BOM.json" vm vm-control-01

ansible-playbook -i "$ANSIBLE_DIR/inventories/inventory.json" \
  "$ANSIBLE_DIR/playbooks/proxmox/create-vm.yml" \
  --extra-vars "component_ref=vm-control-01" \
  --vault-password-file=<(echo "$VAULT_PASS")

# 12) Copy SSH key & Ansible bootstrap into control01
CONTROL_IP=$(jq -r '._meta.hostvars["vm-control-01"].ansible_host' \
  "$ANSIBLE_DIR/inventories/inventory.json")

sshpass -p "$PVE_PASS" ssh-copy-id \
  -o StrictHostKeyChecking=no root@"$CONTROL_IP"

scp -rp "$ANSIBLE_DIR" root@"$CONTROL_IP":/etc/ansible

# 13) Final message
echo "MariaDB LXC & control01 VM are live!"
echo "Proceed further configuration from control01:"
echo "  ssh root@${CONTROL_IP}"
