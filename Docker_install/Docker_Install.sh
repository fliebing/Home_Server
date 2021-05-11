#!/bin/bash
##################################################################################################
#    This is a setup bash for the environment variables needed to run the docker containers      #
#    make executable with:                                                                       #
#        chmod 0755 Docker_install.sh or chmod +x Docker_install.sh                              #
#    excute in terminal via source ./installer.sh                                                #
# WARNING: Always examine scripts downloaded from the internet before running them locally!!     #
##################################################################################################

clear
# Remove old versions of docker 
sudo apt-get remove docker docker-engine docker.io containerd runc

# Update system to ensure latest versions are installed 
sudo apt-get update

#Install Pre Reqs
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

#Download latest version of Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
#I need to fix this par, but this works for now, choose your machines architecture
cpuarch=$(uname -m)
echo "Select correct Architecture, tour system says you have ($cpuarch) [(1)x86_64/amd64, (2)armhf, (3)arm64]" 
read -p "...........................................         1,2 or 3?:" arch
echo ""
if [ arch == "1" ]; then
    echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
elif [ arch == "2" ]; then
    echo \
  "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
elif [ arch == "3" ]; then
    echo \
  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
else
   echo "Invalid architecture, please install manually"
   exit 1
fi

#Update with new repo
sudo apt-get update

#Install Docker
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add Docker group
sudo groupadd docker
#Remember to add your users to this group if you will not be using the rest of my scripts
# this is done by: sudo usermod -aG docker username

# Download docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

#ensure that the binary is executable
sudo chmod +x /usr/local/bin/docker-compose

#enable docker on startup
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

echo "Finished installing Docker and Docker compose"