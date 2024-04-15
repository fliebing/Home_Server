#!/bin/bash
##################################################################################################
#    This is a setup bash for the environment variables needed to run the docker containers      #
#    make executable with:                                                                       #
#        chmod 0755 default_config.sh or chmod +x default_config.sh                              #
#    excute in terminal via source ./default_config.sh                                           #
#   WARNING: Always examine scripts downloaded from the internet before running them locally!!   #
##################################################################################################

clear

username=$(whoami)
if [ $(id -u) -eq 0 ]; then
        read -p "Enter username for docker containers on host: (do not use root)" username
    echo ""

else
    read -p "Do you wish to use this same user ($username) for Docker?(Y/n)" yn
    if [[ $yn == "N"  || $yn == "n" ]]; then
        read -p "What user will you use for Docker? (Not root)" username
        echo ""
    fi
fi
if [[ $username == "root" || $username == "admin" || $username == "Admin" || $username == "ADMIN" || $username == "" ]]; then
    echo "Cannot use admin, root or blank, using docker instead"
    username="docker"
fi
egrep "^$username" /etc/passwd >/dev/null
if [ $? -eq 0 ]; then
    echo "$username exists!"
else
    # Auto-Generate Strong Password for user
    pass=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&^*_'\' </dev/urandom | head -c 21 ; echo)
    # Generate user and password
    sudo useradd -m -p "$pass" "$username"
    if [ $? -eq 0 ]; then
        echo "User ($username) has been added to system"
        echo "The password is: "$pass
        echo "Please write it down as it is not stored anywhere"
        read -p "Hit any key to continue once you have the password" -n 1
        echo ""
        clear
    else
        echo "Failed to add a user ($username), Please try again"
        exit 2
    fi
fi

# Create Docker group
#check if group already exists
echo "Checking if group exists"
groupexists=$(getent group | grep docker | awk -F: '{ print $1}')
if [ "$groupexists" != "docker" ]; then
    echo "Group does not exist, adding group (docker)"
    sudo groupadd docker
else
    echo "Group exists already, continuing"
fi
echo "Adding user to group"
sudo usermod -aG docker $username


# Environment Varibales to use
echo "Generating environment Variables"
PUID=$( id $username -u )
GUID=$( getent group | grep docker | awk -F: '{ print $3}' )
TZ=$(timedatectl | grep 'Time zone' | awk -F '\ ' '{print $19}')
USERDIR="/opt/docker"
DBPASS=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&^*_'\' </dev/urandom | head -c 21 ; echo)
DBROOT=$(LC_ALL=C tr -dc 'A-Za-z0-9!"#$%&^*_'\' </dev/urandom | head -c 21 ; echo)
ENVFILE="$USERDIR/.env"
COMPOSEFILE="$USERDIR/docker-compose.yml"
Hostname=$(hostname)

clear
echo "*******************************************************"
echo "*       Assign ports to desired docker images         *"
echo "*  Use \"enter\" for any image you do not want to install *"
echo "*    Use \"X\"for any image you do not want to install   *"
echo "*    Use \"x\" for any image you do not want to install   *"
echo "*******************************************************"
echo ""
echo "Currently used ports are:"
echo $(sudo ss -tulwn | grep LISTEN | awk -F: '{ gsub (" ", "^", $0); print $2}'| awk -F^ '{print $1}')

read -p "Port to use for Portainer:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="PORTAINERPORT=$PORT:9000"
    COMPOSECONFIG=" #Portainer - WebUI for Containers
  portainer:
    image: \"portainer/portainer\"
    hostname: portainer
    container_name: \"portainer\"
    restart: always
    command: -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - \${USERDIR}/portainer/data:/data
      - \${USERDIR}/shared:/shared
    ports:
      - \${PORTAINERPORT}
    environment:
      - TZ=\${TZ}"
fi
read -p "Port to use for ORGANIZR:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nORGANIZRPORT=$PORT:80"
    COMPOSECONFIG="$COMPOSECONFIG

    # Organizer - Unified HTPC/Home Server Web Interface
  organizr:
    image: \"lsiocommunity/organizr\"
    hostname: organizr
    container_name: \"organizr\"
    restart: always
    volumes:
      - \${USERDIR}/organizr:/config
      - \${USERDIR}/shared:/shared
    ports:
      - \${ORGANIZRPORT}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for phpmyadmin:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nphpmyadminport=$PORT:80"
    COMPOSECONFIG="$COMPOSECONFIG

    # WebUI for MariaDB
  phpmyadmin:
    image: \"phpmyadmin/phpmyadmin\"
    hostname: phpmyadmin
    container_name: \"phpmyadmin\"
    restart: always
    links:
      - mariadb:db
    ports:
      - \${phpmyadminport}
    environment:
      - PMA_HOST=mariadb
      - MYSQL_ROOT_PASSWORD=\${DBROOT}"
fi
read -p "Port to use for HASSIO:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nHASSIOPORT=$PORT:8123"
    COMPOSECONFIG="$COMPOSECONFIG

# Home Assistant - Smart Home Hub
  homeassistant:
    image: \"homeassistant/home-assistant\"
    hostname: hass
    container_name: \"homeassistant\"
    restart: always
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
      - /dev/ttyUSB1:/dev/ttyUSB1
#      - /dev/ttyACM0:/dev/ttyACM0
    volumes:
      - \${USERDIR}/homeassistant:/config
      - /etc/localtime:/etc/localtime:ro
      - \${USERDIR}/shared:/shared
    ports:
      - \${HASSIOPORT}
    privileged: true
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Install qbittorrent? [N,y]" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" && $PORT != "N" && $PORT != "n" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nqbittorrentwebuiport=9704"
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nqbittorrentTCPUDP=6881"
    COMPOSECONFIG="$COMPOSECONFIG

# qBittorrent without VPN – Bittorrent Downloader (Alternative to transmission)
  qbittorrent:
    image: \"linuxserver/qbittorrent\"
    hostname: qbittorrent
    container_name: \"qbittorrent\"
    restart: always
    volumes:
      - \${USERDIR}/qbittorrent:/config
      - \${USERDIR}/Downloads/completed:/downloads
      - \${USERDIR}/shared:/shared
    ports:
      - \${qbittorrentwebuiport}:\${qbittorrentwebuiport}
      - \${qbittorrentTCPUDP}:\${qbittorrentTCPUDP}
      - \${qbittorrentTCPUDP}:\${qbittorrentTCPUDP}/udp
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
      - UMASK_SET=002
      - WEBUI_PORT=\${qbittorrentwebuiport}"
fi
read -p "Port to use for sabnzbd:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
        PORTTRANSLATIONS="$PORTTRANSLATIONS\nsabnzbdport=$PORT:8080"
        COMPOSECONFIG="$COMPOSECONFIG

# SABnzbd – Usenet (NZB) Downloader
  sabnzbd:
    image: \"linuxserver/sabnzbd\"
    hostname: sabnzbd
    container_name: \"sabnzbd\"
    restart: always
    volumes:
      - \${USERDIR}/sabnzbd:/config
      - \${USERDIR}/Downloads/completed:/downloads
      - \${USERDIR}/Downloads/incomplete:/incomplete-downloads
      - \${USERDIR}/shared:/shared
    ports:
        - \${sabnzbdport}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for radarr:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nradarrport=$PORT:7878"
    COMPOSECONFIG="$COMPOSECONFIG

# Radarr – Movie Download and Management
  radarr:
    image: \"linuxserver/radarr\"
    hostname: radarr
    container_name: \"radarr\"
    restart: always
    volumes:
      - \${USERDIR}/radarr:/config
      - \${USERDIR}/Downloads/completed:/downloads
      - \${USERDIR}/media/movies:/movies
      - \"/etc/localtime:/etc/localtime:ro\"
      - \${USERDIR}/shared:/shared
    ports:
      - \${radarrport}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"

fi
read -p "Port to use for sonarr:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nsonarrport=$PORT:8989"
    COMPOSECONFIG="$COMPOSECONFIG

# Sonarr – TV Show Download and Management
  sonarr:
    image: \"linuxserver/sonarr\"
    hostname: sonarr
    container_name: \"sonarr\"
    restart: always
    volumes:
      - \${USERDIR}/sonarr:/config
      - \${USERDIR}/Downloads/completed:/downloads
      - \${USERDIR}/media/tvshows:/tv
      - \"/etc/localtime:/etc/localtime:ro\"
      - \${USERDIR}/shared:/shared
    ports:
        - \${sonarrport}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for lidarr:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nlidarrport=$PORT:8686"
    COMPOSECONFIG="$COMPOSECONFIG

#LIDARR - Music Download and Management
  lidarr:
    image: \"linuxserver/lidarr\"
    hostname: lidarr
    container_name: \"lidarr\"
    restart: always
    volumes:
      - \${USERDIR}/lidarr:/config
      - \${USERDIR}/Downloads:/downloads
      - \${USERDIR}/media/music:/music
      - \"/etc/localtime:/etc/localtime:ro\"
      - \${USERDIR}/shared:/shared
    ports:
      - \${lidarrport}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for ombi:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nombiport=$PORT:3579"
    COMPOSECONFIG="$COMPOSECONFIG

# Ombi – Accept Requests for your Media Server
  ombi:
    image: \"linuxserver/ombi\"
    hostname: ombi
    container_name: \"ombi\"
    restart: always
    volumes:
      - \${USERDIR}/ombi:/config
      - \${USERDIR}/shared:/shared
    ports:
      - \${ombiport}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for HYDRA:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nHYDRAPORT=$PORT:5075"
    COMPOSECONFIG="$COMPOSECONFIG

# NZBHydra – NZB Meta Search
  hydra:
    image: \"linuxserver/hydra\"
    hostname: hydra
    container_name: \"hydra\"
    restart: always
    volumes:
      - \${USERDIR}/hydra:/config
      - \${USERDIR}/Downloads:/downloads
      - \${USERDIR}/shared:/shared
    ports:
      - \${HYDRAPORT}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for JACKETT:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nJACKETTPORT=$PORT:9117"
    COMPOSECONFIG="$COMPOSECONFIG

# Jackett – Torrent Proxy
  jackett:
    image: \"linuxserver/jackett\"
    hostname: jackett
    container_name: \"jackett\"
    restart: always
    volumes:
      - \${USERDIR}/jackett:/config
      - \${USERDIR}/Downloads/completed:/downloads
      - \"/etc/localtime:/etc/localtime:ro\"
      - \${USERDIR}/shared:/shared
    ports:
      - \${JACKETTPORT}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
read -p "Port to use for NEXTCLOUD:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nNEXTCLOUDPORT=$PORT:443"
    COMPOSECONFIG="$COMPOSECONFIG

# NextCloud – Your Own Cloud Storage
  nextcloud:
    image: \"linuxserver/nextcloud\"
    hostname: nextcloud
    container_name: \"nextcloud\"
    restart: always
    volumes:
      - \${USERDIR}/nextcloud:/config
      - \${USERDIR}/shared_data:/data
      - \${USERDIR}/shared:/shared
    ports:
      - \${NEXTCLOUDPORT}
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}"
fi
read -p "Port to use for PAI:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nPAIPORT=$PORT:10000"
    COMPOSECONFIG="$COMPOSECONFIG

# PAI- Paradox Alarm Interface 
  pai:
    image: \"paradoxalarminterface/pai:latest\"
    hostname: pai
    container_name: \"pai\"
    restart: unless-stopped
    volumes:
      - \${USERDIR}/pai:/etc/pai:ro
      - \${USERDIR}/pai/log:/var/log/pai:rw
      - \"/etc/timezone:/etc/timezone:ro\"
      - \"/etc/localtime:/etc/localtime:ro\"
    ports:
      - \${PAIPORT}
    environment:
      - TZ=\${TZ}
    user: \${PUID}:\${PGID}
    depends_on:
      - mosquitto"
fi
read -p "Port to use for FreePBX:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\npbxport=$PORT:3579"
    COMPOSECONFIG="$COMPOSECONFIG

# FREEPBX & Asterisk – PBX system for VOiP calls in house
  PBX:
    image: \"tiredofit/freepbx\"
    hostname: freepbx
    container_name: \"pbx\"
    restart: always
    volumes:
      - \${USERDIR}/pbx:/config
      - \${USERDIR}/shared:/shared
    ports:
      - \"\$pbxport\"
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}"
fi
echo ""
echo ""
echo "Generating environment variables file $ENVFILE"

# Generting the Environment Variable file
envexist=$(ls $ENVFILE)
if [[ "$envexist" == "" ]]; then
    sudo touch $ENVFILE
    echo "File was created"
    echo "adding basic info"

    sudo tee -a $ENVFILE > /dev/null <<EOF
# ------------------------------
# Default machine  and location configuration
# ------------------------------

HOSTNAME=$Hostname
TZ=$TZ
USERDIR=$USERDIR
PUID=$PUID
GUID=$GUID

# ------------------------------
# SQL database configuration
# ------------------------------
# Please use long, random alphanumeric strings (A-Za-z0-9)

DBUSER=$username
DBPASS=$DBPASS
DBROOT=$DBROOT

# ------------------------------
# Port Translations
# ------------------------------


EOF

else
    echo "ENV file already exists, please update manually as this scripts overwrites the DB information and may damage your environment."
    exit 1
fi

echo "EOF reached continuing with addition of the variables"

# Sending info to file
echo -e "$PORTTRANSLATIONS" | sudo tee -a $ENVFILE > /dev/null

# Generting the DOCKER-COMPOSE YAML file
composexist=$(ls $COMPOSEFILE)
if [[ "$composexist" == "" ]]; then
    sudo touch $COMPOSEFILE
    echo "File was created"
    echo "adding basic info"

    sudo tee -a $COMPOSEFILE > /dev/null <<EOF

version: "3.6"
services:

######### Always Installed ##########

# MariaDB – Database Server for your Apps
#You want to have databases local so they dont ipact perfromance
  mariadb:
    image: "linuxserver/mariadb"
    hostname: mariadb
    container_name: "mariadb"
    restart: always
    volumes:
        - \${USERDIR}/mariadb:/config
        - \${USERDIR}/mariadb/mysql_data:/var/lib/mysql
        - "/etc/localtime:/etc/localtime:ro"
    ports:
      - target: 3306
        published: 3306
        protocol: tcp
        mode: host
    environment:
      - MYSQL_ROOT_PASSWORD=${DBROOT}
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}

# Mosquitto - MQTT
# Broker is quite handy to have, this may be disabeld if not needed.
  mosquitto:
    image: "eclipse-mosquitto"
    hostname: mosquitto
    container_name: "mosquitto"
    restart: unless-stopped
    volumes:
      - \${USERDIR}/mosquitto/data:/mosquitto/data
      - \${USERDIR}/mosquitto/logs:/mosquitto/logs
      - \${USERDIR}/mosquitto:/mosquitto/config
    ports:
      - 1883:1883
      - 8883:8883

# Watchtower - Automatic Update of Containers/Apps
# This keeps the images updated, so you dot have to.

  watchtower:
    image: "v2tec/watchtower"
    hostname: watchtower
    container_name: watchtower
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --schedule "0 0 4 * * *" --cleanup


    ########################################
    #     Dynamically built environment    #
    ########################################


EOF
else
    echo "docker-compose.yml file already exists, please update manually as this scripts overwrites the yml completely and may damage your environment."
    exit 1
fi

echo "EOF reached continuing with addition of the variables"

# Sending info to file
echo -e "$COMPOSECONFIG" | sudo tee -a $COMPOSEFILE > /dev/null
echo ""
echo ""
echo ""
echo "*************Configuration is complete*************"
echo "*  All the configurations have been loaded to     *"
echo "*  the system, review $COMPOSEFILE *"
echo "*  and $ENVFILE       *"
echo "* to ensure system configuration is complete and  *"
echo "*  then run docker-compose up to get images and   *"
echo "*  start onfiguring your environment.             *"
echo "*************Configuration is complete*************"

read -p "Hit any key to finish" -n 1
echo ""
clear
