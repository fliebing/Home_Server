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
This repo is dedicated to automating tasks for buildout of several home servers, I have made sure to include media, downloader, pbx (Please make sure that you understand the pro/cons of setting up a PBX inside docker), etc.

The base install will always place a mariadb database, mosquitto and Watchtower to ensure that the images are kept up to date in time.

## Topological “build” (provision) order

So that every component is brought up only once all of its dependencies exist:

### Physical/network devices:
1) router-isp
1) switch-distribution
1) hw-opnsense (Router)

### Hypervisor hosts
1) hw-pve1 
1) hw-pve0  (needed later for some VMs/CTs)
1) hw-ai1 (AI bare metal system)

### Control-plane VM
1) vm-control-01 (depends on hw-pve1)

For this VM you will need to run:
```
chmod +x build-vm-control1.sh
./build-vm-control1.sh 
```


### Core database containers & CI/CD
1) ct-central-db-mariadb (depends on vm-control-01)
1) ct-central-db-qdrant (depends on vm-control-01)
1) ct-cicd (depends on vm-control-01)

### Front-end & collaboration services
1) ct-106-frontend01 (depends on ct-central-db-mariadb)
1) vm-collab-suite (depends on ct-central-db-mariadb)

### Monitoring & “glue” containers
1) vm-monitoring (depends on vm-collab-suite)
1) ct-homarr (depends on vm-monitoring)
1) ct-pbx (depends on vm-collab-suite)

### Entertainment & AI workloads
1) vm-entertainment (depends on vm-collab-suite)
1) vm-ollama (depends on both hw-ai1 and ct-central-db-qdrant)

## Why this order?

Hosts must exist before any VM/CT lands on them.
vm-control-01 is the linchpin: most higher-level services pull configs, credentials or SBOM tools from it.
Databases and CI/CD clone off the control VM.
The front-end and collab-suite sit atop the DBs.
Monitoring then “glue” (Homarr, PBX) need the collab suite.
Finally, entertainment and the GPU-backed Ollama only come up once their upstream data stores and hardware are ready.


# **Arch_install**
This script is to be able to easily and quickly rollout an Arch-Linux server to th evironment, the only requisite is to have booted from the Arch CD/DVD.





