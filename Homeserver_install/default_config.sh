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
Hostname=$(hostname)

clear
echo "*******************************************************"
echo "*       Assign ports to desired docker images         *"
echo "*  Use enter for any image you do not want to install *"
echo "*    Use X for any image you do not want to install   *"
echo "*    Use x for any image you do not want to install   *"
echo "*******************************************************"
echo ""
echo "Currently used ports are:"
echo $(sudo ss -tulwn | grep LISTEN | awk -F: '{ gsub (" ", "^", $0); print $2}'| awk -F^ '{print $1}')

read -p "Port to use for Portainer:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="PORTAINERPORT=$PORT:9000"
fi    
read -p "Port to use for ORGANIZR:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nORGANIZRPORT=$PORT:80"
fi
read -p "Port to use for phpmyadmin:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nphpmyadminport=$PORT:80"
fi
read -p "Port to use for HASSIO:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nHASSIOPORT=$PORT:8123"
fi
read -p "Install qbittorrent? [N,y]" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" && $PORT != "N" && $PORT != "n" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nqbittorrentwebuiport=9704"
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nqbittorrentTCPUDP=6881"
fi
read -p "Port to use for sabnzbd:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
        PORTTRANSLATIONS="$PORTTRANSLATIONS\nsabnzbdport=$PORT:8080"
fi
read -p "Port to use for radarr:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nradarrport=$PORT:7878"
fi
read -p "Port to use for sonarr:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nsonarrport=$PORT:8989"
fi
read -p "Port to use for lidarr:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nlidarrport=$PORT:8686"
fi
read -p "Port to use for ombi:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nombiport=$PORT:3579"
fi
read -p "Port to use for HYDRA:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nHYDRAPORT=$PORT:5075"
fi
read -p "Port to use for JACKETT:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nJACKETTPORT=$PORT:9117"
fi
read -p "Port to use for NEXTCLOUD:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nNEXTCLOUDPORT=$PORT:443"
fi
read -p "Port to use for PAI:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\nPAIPORT=$PORT:10000"
fi
read -p "Port to use for FreePBX:" PORT
if [[ $PORT != "X" && $PORT != "x" && $PORT != "" ]]; then
    PORTTRANSLATIONS="$PORTTRANSLATIONS\npbxport=$PORT:3579"
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
echo -e "$PORTTRANSLATIONS" | sudo tee -a $ENVFILE
