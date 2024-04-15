#!/bin/bash
##################################################################################################
#    This is a setup bash for the environment variables needed to run the PXE images through     #
#    TFTP and HTTPS make executable with:                                                        #
#        chmod 0755 default_config.sh or chmod +x default_config.sh                              #
#    excute in terminal via source ./default_config.sh                                           #
#   WARNING: Always examine scripts downloaded from the internet before running them locally!!   #
##################################################################################################

read -p "Press enter to continue" anykey
read -p "IP of the OPNSENSE box?: " OPNIP
read -p "IP of the OPNSENSE box?: " OPNIP
clear

