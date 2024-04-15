## Overview:

PXE servers have 2 parts:

TFTP server to serve the bootloader and other files necessary for network booting.
DHCP configuration to respond to PXE requests with info including where to find the TFTP server and the bootloader file to start the network booting process.


### Adding SSH key to OPNsense:
1. Create SSH key in local computer: 

for MAC use:
``` ssh-keygen -t ed25519  ``` 
```
        you will find the SSH key generated in ~/.ssh
```

2. Copy the public key to your clipboard. (the one ending in .pub)

for MAC use:
  ``` pbcopy < ~/.ssh/id_rsa.pub ```

2. Browse to OPNsense and login.
3. Navigate to System, Access, Users. 
4. Locate the user you want the SSH key for (e.g. root) and click the pencil icon to edit.
5. At the bottom of the page paste the public key into the Authorized Keys field. 
====================================================================================
6. Navigate to System, Settings, Administration.
7. Scroll down to the Secure Shell portion and:
```
7.1. tick the Enable Secure Shell
7.2. tick Permit root user login (ONLY IF USING ROOT AS YOUT USER, PLEASE DON'T)
7.3. untick the Permit Password login box.
```
8. If you haven’t already enabled SSH, you can do it here as well. 
9. Scroll all the way down and click Save.
10. Go to a terminal and run ```ssh root@YOUR_Firewall_IP}```



### TFTP/HTTP/PXE setup:

1. Install the tftp plugin in OPNSense

        1. Go to System > Firmware > Plugins. 
        2. Search for os-tftp. 
        3. Click on the + sign at the end of the row to install it.

You will get a message:

 ``` The root folder for transfering files is /usr/local/tftp. ```

Once the WebUI refreshes entry appears in Services > TFTP > General where the service can be enabled or disabled.
Go to the TFTP item in the Services and enable it, place listener ot 0.0.0.0 (all interfaces)

2. SSH into your web server and create the Directories we will need for the images: I am going to use ARCH and Debian as an example
```
mkdir -p /usr/share/nginx/isos/ARCH/
mkdir -p /usr/share/nginx/isos/Debian/
mkdir /etc/nginx/sites-available
mkdir /etc/nginx/sites-enabled
```

3. Now Create the website and enable it to serve the static files to our PXE clients:
```
touch /etc/nginx/sites-available/isos
    tee -a /etc/nginx/sites-available/isos > /dev/null <<EOF
server {
    listen        8080 default_server;
        root /usr/share/nginx/isos;

        # Add index.php to the list if you are using PHP
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location / {
                # First attempt to serve request as file, then
                # as directory, then fall back to displaying a 404.
#                try_files $uri $uri/ =404;
                autoindex on;
                autoindex_exact_size off;
        }
}

EOF

ln -s /etc/nginx/sites-available/isos /etc/nginx/sites-enabled/
```
NOTE:To enable a site, simply create a symlink:
```
ln -s /etc/nginx/sites-available/example.conf /etc/nginx/sites-enabled/example.conf
```
To disable a site, unlink the active symlink:
```
unlink /etc/nginx/sites-enabled/example.conf
```
Reload/restart nginx.service to enable changes to the site's configuration.

We need to include the preseed information for Debian.
```
touch /usr/share/nginx/isos/Debian/preseed.cfg
    tee -a /usr/share/nginx/isos/Debian/preseed.cfg > /dev/null <<EOF
    #_preseed_V1

# B.4.1. Localization

d-i debian-installer/language string en
d-i debian-installer/country string US
d-i debian-installer/locale string en_US.UTF-8
d-i keyboard-configuration/xkb-keymap select us

# B.4.2. Network configuration

# B.4.3. Network console

# B.4.4. Mirror settings

d-i mirror/protocol string http
d-i mirror/country string manual
d-i mirror/http/hostname string ftp.us.debian.org
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string
d-i mirror/suite string bookworm

# B.4.5. Account setup

d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password password trivial
d-i passwd/root-password-again password trivial

# B.4.6. Clock and time zone setup

d-i clock-setup/utc boolean true
d-i time/zone string Etc/UTC
d-i clock-setup/ntp boolean true
d-i clock-setup/ntp-server string debian.pool.ntp.org

# B.4.7. Partitioning

d-i partman-auto/disk string /dev/vda
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true

# B.4.7.3. Controlling how partitions are mounted

d-i partman/mount_style select uuid

# B.4.8. Base system installation

d-i base-installer/kernel/image string linux-image-amd64

# B.4.9. Apt setup

d-i apt-setup/non-free-firmware boolean false
d-i apt-setup/non-free boolean false
d-i apt-setup/contrib boolean false
d-i apt-setup/disable-cdrom-entries boolean true
d-i apt-setup/services-select multiselect security, updates
d-i apt-setup/security_host string security.debian.org
d-i debian-installer/allow_unauthenticated boolean false

# B.4.10. Package selection

tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/upgrade select full-upgrade
popularity-contest popularity-contest/participate boolean false

# B.4.11. Boot loader installation

d-i grub-installer/only_debian boolean true
d-i grub-installer/bootdev string /dev/vda

# B.4.12. Finishing up the installation

d-i finish-install/reboot_in_progress note
d-i cdrom-detect/eject boolean true

# B.4.13. Preseeding other packages

# B.5.1. Running custom commands during the installation

d-i preseed/late_command string \
  in-target apt-get -y purge installation-report; \
  \
  >>/target/etc/apt/sources.list echo deb http://ftp.us.debian.org/debian bookworm main; \
  >>/target/etc/apt/sources.list echo deb http://deb.debian.org/debian-security/ bookworm-security main; \
  >>/target/etc/apt/sources.list echo deb http://ftp.us.debian.org/debian bookworm-updates main; \
  in-target apt-get update; \
  in-target apt-get -y dist-upgrade; \
  \
  mkdir -p /target/etc/issue.d; \
  >>/target/etc/issue.d/ip-addresses.issue echo \\4 \\6; \
  >>/target/etc/issue.d/ip-addresses.issue echo; \
  \
  >/target/etc/nftables.conf echo \#!/usr/sbin/nft -f; \
  >>/target/etc/nftables.conf echo flush ruleset; \
  >>/target/etc/nftables.conf echo table inet filter {; \
  >>/target/etc/nftables.conf echo  chain input {; \
  >>/target/etc/nftables.conf echo   type filter hook input priority filter; \
  >>/target/etc/nftables.conf echo   policy drop; \
  >>/target/etc/nftables.conf echo   ct state established,related accept; \
  >>/target/etc/nftables.conf echo   iifname lo accept; \
  >>/target/etc/nftables.conf echo   ip protocol icmp accept; \
  >>/target/etc/nftables.conf echo   ip6 nexthdr icmpv6 accept; \
  >>/target/etc/nftables.conf echo   ip6 nexthdr ipv6-icmp accept; \
  >>/target/etc/nftables.conf echo   tcp dport 22 accept; \
  >>/target/etc/nftables.conf echo  }; \
  >>/target/etc/nftables.conf echo  chain forward {; \
  >>/target/etc/nftables.conf echo   type filter hook forward priority filter; \
  >>/target/etc/nftables.conf echo   policy accept; \
  >>/target/etc/nftables.conf echo  }; \
  >>/target/etc/nftables.conf echo  chain output {; \
  >>/target/etc/nftables.conf echo   type filter hook output priority filter; \
  >>/target/etc/nftables.conf echo   policy accept; \
  >>/target/etc/nftables.conf echo  }; \
  >>/target/etc/nftables.conf echo }; \
  in-target chmod 700 /etc/nftables.conf; \
  in-target chown root:root /etc/nftables.conf; \
  in-target systemctl enable nftables.service; \
  \
  mkdir -p /target/etc/ssh/sshd_config.d; \
  >>/target/etc/ssh/sshd_config.d/permit-root-login.conf echo PermitRootLogin yes;

EOF
```






4. Now SSH into opnsense. Press 8 for Shell.

5. Make the directory we will use for the TFTP boot files and the temp directory so we can get the boot files needed:

```
mkdir -p /usr/local/tftp/pxelinux.cfg  
mkdir /var/tmp/deleteme
```

6. Get Syslinux boot files and Linyx Distro ISO you want to use.
```
cd /var/tmp/deleteme
curl -O https://mirrors.edge.kernel.org/pub/linux/utils/boot/syslinux/syslinux-4.04.tar.bz2
tar xvjf /var/tmp/deleteme/syslinux-4.04.tar.bz2 -C /var/tmp/deleteme

cp /var/tmp/deleteme/syslinux-4.04/gpxe/gpxelinux.0 /usr/local/tftp
cp /var/tmp/deleteme/syslinux-4.04/com32/menu/menu.c32 /usr/local/tftp
cp /var/tmp/deleteme/syslinux-4.04/com32/menu/vesamenu.c32 /usr/local/tftp
cp /var/tmp/deleteme/syslinux-4.04/com32/modules/reboot.c32 /usr/local/tftp
cp /var/tmp/deleteme/syslinux-4.04/com32/modules/chain.c32 /usr/local/tftp
cp /var/tmp/deleteme/syslinux-4.04/memdisk/memdisk /usr/local/tftp
```
NOTE: We could use the TFTP server for everything, but it is better to use a web server to host the files, as it is much faster. I am not using the web server to download and mount these files as in the Turnkey deplyment you are not going to be able to mount the images, so this is faster.

###        a. For ARCH Linux
 ```
curl -O https://geo.mirror.pkgbuild.com/iso/2024.03.29/archlinux-2024.03.29-x86_64.iso
mount -t cd9660 /dev/`mdconfig -a -t vnode -f archlinux-2024.03.29-x86_64.iso` /mnt
scp -r /mnt/arch/ root@{httpserver IP}:/usr/share/nginx/isos/ARCH/
umount /mnt
```
###        b. For Debian
```
curl -O https://deb.debian.org/debian/dists/bookworm/main/installer-amd64/current/images/netboot/netboot.tar.gz
tar xvzf /var/tmp/deleteme/netboot.tar.gz -C /var/tmp/deleteme
scp -r /var/tmp/deleteme/debian-installer/ root@{httpserver IP}:/usr/share/nginx/isos/Debian/
```

7. Clean up the TFTP server.
```
cd /usr/local/tftp
rm -rf /var/tmp/deleteme
```

8. Create the config file for pxelinux at /usr/local/tftp/pxelinux.cfg/default containing the following:
```
touch /usr/local/tftp/pxelinux.cfg/default
    tee -a /usr/local/tftp/pxelinux.cfg/default > /dev/null <<EOF
DEFAULT vesamenu.c32
PROMPT 0
timeout 300
ONTIMEOUT local

MENU TITLE PXE Boot Menu (Installers)
LABEL local
        MENU LABEL Boot local hard drive
        MENU LABEL boot_hd0
        COM32 chain.c32
        APPEND hd0

LABEL archlinux
        MENU LABEL Arch Linux diskless/live x86_64
        LINUX http://{httpserver IP}:8080/ARCH/arch/boot/x86_64/vmlinuz-linux
        INITRD http://{httpserver IP}:8080/ARCH/arch/boot/intel-ucode.img,http://{httpserver IP}:8080/ARCH/arch/boot/amd-ucode.img,http://{httpserver IP}:8080/ARCH/arch/boot/x86_64/initramfs-linux.img
        APPEND ip=dhcp checksum=y archiso_http_srv=http://{httpserver IP}:8080/ archisobasedir=ARCH/arch

LABEL Debian install
        MENU LABEL Install Debian
        kernel http://{httpserver IP}:8080/Debian/debian-installer/amd64/linux
        append ip=dhcp vga=788 preseed/url=http://{httpserver IP}:8080/Debian/preseed.cfg initrd=http://{httpserver IP}:8080/Debian/debian-installer/amd64/initrd.gz --- quiet

EOF
```

9. SSH back into the HTTP server to fix ownership, permissions and restart nginx:
```
chown -R http:http /usr/share/nginx/
chmod +777 /usr/share/nginx/isos
nginx -t
systemctl restart nginx
```

10. OPNsense configuration

Navigate to Services > ISC DHCPv4 > [LAN]

Expand TFTP Server. by clicking on Advanced
```
Set TFTP hostname:        {your opnsense IP}  # the TFTP server, aka our OPNsense device's IP
Set Bootfile: gpxelinux.0   # This is the one we are using and has been tested in this setup, you may use a different one if you like.
```

### Testing
1) From your browser go to http://{httpserver IP}:8080/ and browse the directory structure.

2) Test the TFTP from your local terminal.
```
tftp {your opnsense IP}
> get gpxelinux.0 # transfer from server to local machine
[ctrl+d to exit]
file gpxelinux.0 # display file metadata
```

If you receive a time-out or if the gpxelinux.0 that was downloaded is empty, then check your TFTP configuration again. If it downloaded successfully, then you should test booting up a PC to PXE.

