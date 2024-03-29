# **About this code**
This contains 2 separate files: 
    1. Install script for Docker
    2. Compose code for different home server configurations.

I am updating this code based on a Debian 10 distribution, and will test with other builds in the future.

---

# Change Control
Please wait for the code to be tested before using
Date | Changes | Tested
---------|----------|---------
 MAY/1/2021 | Initial deploy | YES
 MAY/6/2021 | V1.0 Docker Install script | NO
 MAY/6/2021 | V1.0 Homeserver environment Variables build script | YES
 MAY/7/2021 | V1.1 Homeserver now includes docker-compose.yaml creation | YES
 MAY/8/2021 | V1.11 Homeserver now includes freepbx option | NO
 JUL/1/2021 | V1 Arch_install script | NO
 
> **_WARNING: Always examine scripts downloaded from the internet before running them locally!!_** > 

---
---
## _**Docker_install**_

This script installs docker and docker compose on the system.


_Instructions:_

---
> This is a setup bash for the environment variables needed to run the docker containers
> make executable with:  
>        sudo chmod 0755 Docker_install.sh or sudo chmod +x Docker_install.sh 
> excute in terminal via source ./Docker_install.sh 
---
---

## _**Docker_Install**_
Contains the scripts needed to set up Docker, currently it is hard coded to version 1.29.1 of docker-compose, please update this to the latest working version for your needs.


## _**default_config**_
Contains the scripts needed to set up a variety of home server builds based on the components you choose in the install process.
The scripts will generate an environent file and a docker-compose.yml. Please make sure you check the config before pulling up the containers.

**Docker containers that are available are the following:**

1. Portainer: Graphical interface for Docker.
2. Organizr: Web interface to organize applications/UI
3. phpmyadmin: Graphical interface to manage mysql/mariaDB
---
4. nextcloud: Local "cloud" solution for storage and other useful features
5. homeassistant: Open Source Smart home Automation hub
6. pai: Paradox Alarm Interface to coneect to an ip150 moduel for Paradoz alarms (use with Homeassistant/nodered)
7. ombi: App to accept requests for media server (will add plex later on)
---
8. hydra: usenet NZB Meta Search
9. jackett: Torrent proxy
10. qbittorrent: Bittorrent Downloader
11. sabnzbd: Usenet (NZB) Downloader
12. radarr: Movie Download and Management
13. sonarr: TV Show Download and Management
14. lidarr: Music Download and Management
---
15. FREEPBX: Asterisk based PBX (use as a sip gateway if within docker, please read up on issues with virtualizing PBX in docker)
 

_Instructions:_

---
> This is a setup bash for the environment variables needed to run the docker containers
> make executable with:  
>        sudo chmod 0755 default_config.sh or sudo chmod +x default_config.sh 
> excute in terminal via source ./default_config.sh 
---