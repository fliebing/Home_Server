#!/usr/bin/env bash
set -euo pipefail

# 1) Choose next-free “bootstrap” LXC ID (e.g. 2999)
BOOT_ID=2999
TEMPLATE="local:vztmpl/debian-12-standard_12.0-1_amd64.tar.gz"
BRIDGE="vmbr0"
STORAGE="local-lvm"
IPADDR="10.23.20.250/24"
GATEWAY="10.23.20.1"

# 2) Create the bootstrap LXC
pct create $BOOT_ID $TEMPLATE \
  --hostname bootstrap \
  --storage $STORAGE \
  --rootfs $STORAGE:4 \
  --net0 name=eth0,bridge=$BRIDGE,ip=$IPADDR,gw=$GATEWAY \
  --password changeme

pct start $BOOT_ID

# 3) Wait for it to come up
echo "Waiting 30s for bootstrap LXC to get network..."
sleep 30

# 4) Push our scripts into it
#    (assumes your Git repo is already on the host under /opt/infra-automation)
pct exec $BOOT_ID -- mkdir -p /root/provision
pct push $BOOT_ID /opt/infra-automation/Ansible/scripts/bootstrap.sh /root/provision/bootstrap.sh
pct push $BOOT_ID /opt/infra-automation/Ansible/scripts/bom2inventory.py /root/provision/bom2inventory.py
pct push $BOOT_ID /opt/infra-automation/Ansible/scripts/update_bom_id.py /root/provision/update_bom_id.py

# 5) Run bootstrap inside LXC
pct exec $BOOT_ID -- bash -lc "chmod +x /root/provision/bootstrap.sh && /root/provision/bootstrap.sh"

# 6) Tear down the bootstrap LXC
pct stop  $BOOT_ID
pct destroy $BOOT_ID

echo "Bootstrap complete.  All initial LXC/VMs created, control01 ready."
