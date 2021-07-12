#!/bin/bash

clear
echo ""
echo ""
echo "Please make sure you booted from the ARCH linux CD"
read "Do you want to partition the system?: " part_script
case $part_script in

        [yY] | [yY][Ee][Ss] )
                read -p 'what is your disk device called? (/dev/sda):' TGTDEV
                echo -n "Do you want to install on UEFI device? [yes or no]: "
                read uefiyno
                case $uefiyno in

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
  Y # Remove signature - only needed if disk is not new
  t # partition type
  1 # type 1 EFI filesystem
  n # new partition
    # default -  Partition 
    # default - start at beginning of disk 
    # rest of disk size partition
  Y # Remove signature - only needed if disk is not new
  t # partition type
    # default -  Partition #2
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
                                exit 1
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
                read -p 'Done, if everything looks good,please reboot now: REBOOT (Y,N)?' rebootyno
                if rebootyno = [Y|y|'']
                        then 
                                reboot
                        else
                                exit 1
                fi
                ;;

                [nN] | [n|N][O|o] )

                clear
                echo ""
                echo ""
                echo "Assuming this is a reboot and has been partitioned properly."
                echo "Verifying Networking"
                ip addr show
                echo "DO NOT USE THIS SCRIPT, it is not yet completed."
                echo -n "Do you want to configure wifi? [yes or no]: "
                read wifiyno
                case "$wifiyno" in
                        [yY] | [yY][Ee][Ss])
                                echo "Configuring Wlan adapter" 
                                read -p 'WIFI device id (wlan0): ' wlanhw 
                                if wlanhw = '' 
                                then 
                                    wlanhw = "wlan0"
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
                ;;
        *) echo "Invalid input"
                exit 1
                ;;
        esac

clear
echo ""
echo ""
echo "now ACTUALLY installing Arch"
pacstrap -i /mnt base
arch-chroot /mnt
pacman -S linux linux-headers
pacman -S lvm2 base-devel nano networkmanager wpa-supplicant wieless_tools netctl openssh dialog 
systemctl enable sshd
systemctl enable NetworkManager
sed -i 's/HOOKS=(base udev autodetect modconf block filesystems/HOOKS=(base udev autodetect modconf block lvm2 filesystems/g' /etc/mkinitcpio.conf
mkinitcpio -p linux
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
clear
echo ""
echo ""
locale-gen
pacman -S sudo
clear
echo ""
echo ""
echo "install GRUB (FINALLY able to boot from HDD)"
        case $uefiyno in

                [yY] | [yY][Ee][Ss] )
                        echo "UEFI use"
                        pacman -S grub efibootmgr dosfstools os-prober mtools
                        mkdir /boot/EFI
                        mount /dev/sda1 /boot/EFI
                        grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
                ;;
                
                [nN] | [n|N][O|o] )
                        echo "NON-UEFI use"
                        pacman -S grub dosfstools os-prober mtools
                        grub-install --target=i386-pc --recheck /dev/sda
                ;;
                
                *) echo "Invalid input"
                exit 1
                ;;
        esac

cp /usr/share/locale/en\@quot/LC MESSAGES/grub.mo /boot/grub/locale/en.mo
sed -i 's/GRUB_GFXMODE=AUTO/GRUB_GFXMODE=1440x900x32/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
#Generate password for root and new user
passwd
read -p "please enter your new user id:" newuser
useradd -m -g users -G wheel $newuser
passwd $newuser
echo "uncomment %wheel ALL=(ALL) ALL"
wait 20
EDITOR=nano visudo
echo "DONE"
wait 10
reboot
