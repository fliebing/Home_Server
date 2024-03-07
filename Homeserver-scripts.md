# **About this code**

Docker Compose code for different home server configurations.

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

# **Home Server build**
This repo is dedicated to automating tasks for buildout of several home servers, I have made sure to include media, downloaders, pbx (Please make sure that you understnad the pro/cons of setting up a PBX inside docker), etc.

The base install will always place a mariadb database, mosquitto and Watchtower to ensure that the images are kept up to date in time.

You can always edit this in order to customize for your environment. The idea is that you can just download this script in all of your home servers and use it to create the user/databases and configs in order to easily/quickly deploy.

The docker instal script was built in order to help set up docker in a bare-bones Debian 10 buster system. I am going to test in other distros as I need them.


# **Arch_install**
This script is to be able to easily and quickly rollout an Arch-Linux server to th evironment, the only requisite is to have booted from the Arch CD/DVD.





