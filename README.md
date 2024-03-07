# **About this code**

Every MD file in this folder will contain the expalanation to the code in the correponding folder.
This code is provided with no support, as this is documentation of my own lab projects rather than a finished product.

# **Security Information**
Please feel free to use the code for your purposes I am trying to keep the code as clean as possible while allowing the users to choose the passwords being used or generating them randomly and therefore eliminating the possibility that I or anyone else would be able to know the passwords/secrets for the new deployments. 

I am updating this code based on a Debian 10 distribution, and will test with other builds in the future.

---

# Change Control
Please wait for the code to be tested before using
Date | Changes | Tested
---------|----------|---------
 MAY/1/2021 | Initial deploy | YES
 MAY/6/2021 | V1.0 Docker Install script | YES
 MAY/6/2021 | V1.0 Homeserver environment Variables build script | YES
 MAY/7/2021 | V1.1 Homeserver now includes docker-compose.yaml creation | YES
 MAY/8/2021 | V1.11 Homeserver now includes freepbx option | NO
 JUL/1/2021 | V1 Arch_install script | YES
 DEC/5/2022 | K3s cluster process and manual code snippets | YES
 
> **_WARNING: Always examine scripts downloaded from the internet before running them locally!!_** > 

---
---

# **My LAB Environment**
    The lab is a series of small separate mini-pcs. I have a mix of Lenovo, Dell and Protectili mini PCs that host the virtual machines and containers. 
    Overall the way this is built is all systems are connected to a switch in a separate network, redundant connections to the Internet from separate firewalls configured in HA.

    See diagram for details.

                                           +--------------+              +---------+
 +------------------------------+        ---  Firewall 1  -------\       |         |
 |                              |  -----/  +--------------+       --------         |
 |              LAB             --/                                      |  ISP    |
 |            Switch            --\                                   ---- ROUTER  |
 |                              |  -----\  +--------------+   -------/   |         |
 |                              |        --- Firewall 2   ---/           |         |
 +---------------|--------------+          +--------------+              |         |
        /        |       \                                               +---------+
       /         |        \                                                         
      /          |         \                                                        
     /           |          \                                                       
    /            |           \                                                      
+--/--+       +-----+      +-----+                                                  
|     |       |     |      |     |                                                  
| K3S |       | K3S |      | K3S |                                                  
|     |       |     |      |     |                                                  
|     |       |     |      |     |                                                  
| SRV |       | SRV |      | SRV |                                                  
|  +  |       |  +  |      |  +  |                                                  
| WRK |       | WRK |      | WRK |                                                  
+-----+       +--|--+      +-----+                                                  
    \-           |          -/                                                      
      \-        /         -/                                                        
+-------\-------|--------/------+                                                   
|                               |                                                   
|           NAS                 |                                                   
|                               |                                                   
+-------------------------------+   
