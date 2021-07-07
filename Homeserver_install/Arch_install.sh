#!/bin/bash



echo "Please make sure you booted from the ARCH linux CD"
echo "Verifying Networking"
ip addr show
echo "DO NOT USE THIS SCRIPT, it is not yet completed."
echo -n "Do you want to configure wifi? [yes or no]: "
read yno
case "$yno" in
         [yY] | [yY][Ee][Ss])
                echo "Configuring Wlan adapter" 
                read -p 'WIFI device id (wlan0): ' wlanhw 
                if $wlanhw = '' 
                then 
                    $wlanhw = "wlan0"
                fi
                read -p 'WIFI SSID: ' ssid 
                read -sp 'Passphrase:' wifipassphrase 
                iwctl --passphrase $wifipassphrase station $wlanhw connect $ssid
                ip addr show 
                ;;
        [nN] | [n|N][O|o] )
                echo "continue with wired lan only"
                ;;
        *) echo "Invalid input"
                ;;
esac
read -p 'what is your disk device called? (/dev/sda):' TGTDEV
echo -n "Do you want to install on UEFI device? [yes or no]: "
read yno
case $yno in

        [yY] | [yY][Ee][Ss] )
                echo "UEFI use this for mac mini"
                # to create the partitions programatically (rather than manually)
                # we're going to simulate the manual input to fdisk
                # The sed script strips off all the comments so that we can 
                # document what we're doing in-line with the actual commands
                # Note that a blank line (commented as "defualt" will send a empty
                # line terminated with a newline to take the fdisk default.
                sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $TGTDEV
  g # clear the in memory partition table
  n # new partition
    # default - Primary Partition 
    # default - start at beginning of disk 
  +500M  # 500M disk partition
  t # partition type
  1 # type 1 EFI filesystem
  n # new partition
    # default -  Partition 
    # default - start at beginning of disk 
    # rest of disk size partition
  t # partition type
  30 # type 30 Linux LVM
  w # write the partition table
EOF
                TGTDEV='/dev/sda1'
                mkfs.fat -F32 $TGTDEV
                TGTDEV='/dev/sda2'
                ;;

        [nN] | [n|N][O|o] )
                echo "non-UEFI use this for mac mini"
                # to create the partitions programatically (rather than manually)
                # we're going to simulate the manual input to fdisk
                # The sed script strips off all the comments so that we can 
                # document what we're doing in-line with the actual commands
                # Note that a blank line (commented as "defualt" will send a empty
                # line terminated with a newline to take the fdisk default.
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk $TGTDEV
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk 
    # default full disk partition
  t # partition type
  8e # type 8e LVM
  a # make a partition bootable
  w # write the partition table
EOF
                ;;
        *) echo "Invalid input"
                ;;
esac


## Generating LVM Partitions and disks
pvcreate --dataalignment 1m $TGTDEV
vgcreate volgroup0 $TGTDEV
lvcreate -L 30GB volgroup0 -n lv_root
lvcreate -l 100%FREE volgroup0 -n lv_home
modprobe dm_mod
vgscan
vgchange -ay
mkfs.ext4 /dev/volgroup0/lv_root
mkfs.ext4 /dev/volgroup0/lv_home
mount /dev/volgroup0/lv_root /mnt
mkdir /mnt/home
mkdir /mnt/etc
mount /dev/volgroup0/lv_home /mnt/home
genfstab -U -p /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
