#!/bin/bash

# This is a setup bash for docker containers!
# activate via: chmod 0755 installer.sh or chmod +x installer.sh
# go to  /opt/docker/
# excute in terminal via source ./installer.sh
# After initial install you may start your docker compose by navigating to the same directory and 
# executing docker-compose up






echo ""
echo "Welcome! You are executing a setup script bash for docker containers."
echo ""

echo "Do you want to use the Default configurations?"
echo ""
source .env



version: "3.6"
services:

######### Always Installed ##########

# MariaDB – Database Server for your Apps
#You want to have databases local so they dont ipact perfromance
  mariadb:
    image: "linuxserver/mariadb"
    container_name: "mariadb"
    hostname: mariadb
    volumes:
        - ${USERDIR}/mariadb:/config
        - ${USERDIR}/mariadb/mysql_data:/var/lib/mysql
        - /etc/localtime:/etc/localtime:ro
    ports:
      - target: 3306
        published: 3306
        protocol: tcp
        mode: host
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=${DBROOT}
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

# Mosquitto - MQTT
# Broker is quite handy to have, this may be disabeld if not needed.
  mosquitto:
    image: eclipse-mosquitto
    hostname: mosquitto
    container_name: mosquitto
    ports:
      - 1883:1883
      - 8883:8883
    volumes:
      - ${USERDIR}/mosquitto/data:/mosquitto/data
      - ${USERDIR}/mosquitto/logs:/mosquitto/logs
      - ${USERDIR}/mosquitto:/mosquitto/config
    restart: unless-stopped

# Watchtower - Automatic Update of Containers/Apps
# This keeps the images updated, so you dot have to.

  watchtower:
    container_name: watchtower
    hostname: watchtower
    restart: always
    image: v2tec/watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: --schedule "0 0 4 * * *" --cleanup

######### FRONTENDS ##########

 #Portainer - WebUI for Containers
  portainer:
    image: portainer/portainer
    hostname: portainer
    container_name: portainer
    restart: always
    command: -H unix:///var/run/docker.sock
    ports:
      - ${PORTAINERPORT}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${USERDIR}/portainer/data:/data
      - ${USERDIR}/shared:/shared
    environment:
      - TZ=${TZ}

# Organizer - Unified HTPC/Home Server Web Interface
  organizr:
    container_name: organizr
    hostname: organizr
    restart: always
    image: lsiocommunity/organizr
    volumes:
      - ${USERDIR}/organizr:/config
      - ${USERDIR}/shared:/shared
    ports:
      - ${ORGANIZRPORT}
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

# WebUI for MariaDB
  phpmyadmin:
    hostname: phpmyadmin
    container_name: phpmyadmin
    image: phpmyadmin/phpmyadmin
    restart: always
    links:
      - mariadb:db
    ports:
      - ${phpmyadminport}
    environment:
      - PMA_HOST=mariadb
      - MYSQL_ROOT_PASSWORD=${DBROOT}


######### SMART HOME APPS ##########

# Home Assistant - Smart Home Hub
  homeassistant:
    container_name: homeassistant
    hostname: hass
    restart: always
    image: homeassistant/home-assistant
    devices:
      - /dev/ttyUSB0:/dev/ttyUSB0
      - /dev/ttyUSB1:/dev/ttyUSB1
#      - /dev/ttyACM0:/dev/ttyACM0
    volumes:
      - ${USERDIR}/homeassistant:/config
      - /etc/localtime:/etc/localtime:ro
      - ${USERDIR}/shared:/shared
    ports:
      - ${HASSIOPORT}
    privileged: true
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

######### DOWNLOADERS ##########

# qBittorrent without VPN – Bittorrent Downloader (Alternative to transmission)
  qbittorrent:
    image: "linuxserver/qbittorrent"
    hostname: qbittorrent
    container_name: "qbittorrent"
    volumes:
      - ${USERDIR}/qbittorrent:/config
      - ${USERDIR}/Downloads/completed:/downloads
      - ${USERDIR}/shared:/shared
    ports:
      - ${qbittorrentwebuiport}:${qbittorrentwebuiport}
      - ${qbittorrentTCPUDP}:${qbittorrentTCPUDP}
      - ${qbittorrentTCPUDP}:${qbittorrentTCPUDP}/udp
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      - UMASK_SET=002
      - WEBUI_PORT=${qbittorrentwebuiport}

# SABnzbd – Usenet (NZB) Downloader
  sabnzbd:
    image: "linuxserver/sabnzbd"
    hostname: sabnzbd
    container_name: "sabnzbd"
    volumes:
      - ${USERDIR}/sabnzbd:/config
      - ${USERDIR}/Downloads/completed:/downloads
      - ${USERDIR}/Downloads/incomplete:/incomplete-downloads
      - ${USERDIR}/shared:/shared
    ports:
        - ${sabnzbdport}
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

######### MEDIA RECORDERS ##########

# Radarr – Movie Download and Management
  radarr:
    image: "linuxserver/radarr"
    hostname: radarr
    container_name: "radarr"
    volumes:
      - ${USERDIR}/radarr:/config
      - ${USERDIR}/Downloads/completed:/downloads
      - ${USERDIR}/media/movies:/movies
      - "/etc/localtime:/etc/localtime:ro"
      - ${USERDIR}/shared:/shared
    ports:
      - ${radarrport}
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

# Sonarr – TV Show Download and Management
  sonarr:
    image: "linuxserver/sonarr"
    hostname: sonarr
    container_name: "sonarr"
    volumes:
      - ${USERDIR}/sonarr:/config
      - ${USERDIR}/Downloads/completed:/downloads
      - ${USERDIR}/media/tvshows:/tv
      - "/etc/localtime:/etc/localtime:ro"
      - ${USERDIR}/shared:/shared
    ports:
        - ${sonarrport}
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

#LIDARR - Music Download and Management
  lidarr:
    image: "linuxserver/lidarr"
    hostname: lidarr
    container_name: "lidarr"
    volumes:
      - ${USERDIR}/lidarr:/config
      - ${USERDIR}/Downloads:/downloads
      - ${USERDIR}/media/music:/music
      - "/etc/localtime:/etc/localtime:ro"
      - ${USERDIR}/shared:/shared
    ports:
      - ${lidarrport}
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
      
######### MEDIA SERVER APPS ##########

FREEPBX & Asterisk – PBX system for VOiP calls in house
  PBX:
    container_name: pbx
    hostname: pbx
    restart: always
    image: tiredofit/freepbx
    volumes:
      - ${USERDIR}/pbx:/config
      - ${USERDIR}/shared:/shared
    ports:
      - ${pbxport}
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

# Ombi – Accept Requests for your Media Server
  ombi:
    container_name: ombi
    hostname: ombi
    restart: always
    image: linuxserver/ombi
    volumes:
      - ${USERDIR}/ombi:/config
      - ${USERDIR}/shared:/shared
    ports:
      - ${ombiport}
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

######### SEARCHERS ##########

# NZBHydra – NZB Meta Search
  hydra:
    image: "linuxserver/hydra"
    hostname: hydra
    container_name: "hydra"
    volumes:
      - ${USERDIR}/hydra:/config
      - ${USERDIR}/Downloads:/downloads
      - ${USERDIR}/shared:/shared
    ports:
      - ${HYDRAPORT}
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ} 

# Jackett – Torrent Proxy
  jackett:
    image: "linuxserver/jackett"
    hostname: jackett
    container_name: "jackett"
    volumes:
      - ${USERDIR}/jackett:/config
      - ${USERDIR}/Downloads/completed:/downloads
      - "/etc/localtime:/etc/localtime:ro"
      - ${USERDIR}/shared:/shared
    ports:
      - ${JACKETTPORT}
    restart: always
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}

######### UTILITIES ##########

# NextCloud – Your Own Cloud Storage
  nextcloud:
    container_name: nextcloud
    hostname: nextcloud
    restart: always
    image: linuxserver/nextcloud
    volumes:
      - ${USERDIR}/nextcloud:/config
      - ${USERDIR}/shared_data:/data
      - ${USERDIR}/shared:/shared
    ports:
      - ${NEXTCLOUDPORT}
    environment:
      - PUID=${PUID}
      - PGID=${PGID}

# PAI- Paradox Alarm Interface 
  pai:
    container_name: pai
    restart: unless-stopped
    image: paradoxalarminterface/pai:latest
    volumes:
      - ${USERDIR}/pai:/etc/pai:ro
      - ${USERDIR}/pai/log:/var/log/pai:rw
      - /etc/timezone:/etc/timezone:ro
      - /etc/localtime:/etc/localtime:ro
    environment:
      - TZ=${TZ}
    user: ${PUID}:${PGID}
    ports:
      - ${PAIPORT}
    depends_on:
      - mosquitto

