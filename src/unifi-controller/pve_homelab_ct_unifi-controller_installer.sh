#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pve_homelab_ct_unifi_installer.sh
# Description:  This script is for creating a UniFi Controller CT
# Shout Out:    https://glennr.nl/
# ----------------------------------------------------------------------------------

#---- Bash command to run script ---------------------------------------------------

#---- Source Github
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/ahuacate/pve-homelab/main/pve_homelab_installer.sh)"

#---- Source local Git
# /mnt/pve/nas-01-git/ahuacate/pve-homelab/pve_homelab_installer.sh

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

# Check PVE host subid mapping
check_host_subid

# Check SMTP Status
check_smtp_status

#---- Static Variables -------------------------------------------------------------

# Easy Script Section Head
SECTION_HEAD='PVE UniFi Controller'

# PVE host IP
PVE_HOST_IP=$(hostname -i)
PVE_HOSTNAME=$(hostname)

# SSHd Status (0 is enabled, 1 is disabled)
SSH_ENABLE=1

# Developer enable git mounts inside CT  (0 is enabled, 1 is disabled)
DEV_GIT_MOUNT_ENABLE=1

# Set file source (path/filename) of preset variables for 'pvesource_ct_createvm.sh'
PRESET_VAR_SRC="$( dirname "${BASH_SOURCE[0]}" )/$( basename "${BASH_SOURCE[0]}" )"


#---- Other Variables --------------------------------------------------------------

#---- Common Machine Variables
# VM Type ( 'ct' or 'vm' only lowercase )
VM_TYPE='ct'
# Use DHCP. '0' to disable, '1' to enable.
NET_DHCP='0'
#  Set address type 'dhcp4'/'dhcp6' or '0' to disable.
NET_DHCP_TYPE='dhcp4'
# CIDR IPv4
CIDR='24'
# CIDR IPv6
CIDR6='64'
# SSHd Port
SSH_PORT='22'

#----[COMMON_GENERAL_OPTIONS]
# Hostname
HOSTNAME='unifi-controller'
# Description for the Container (one word only, no spaces). Shown in the web-interface CT’s summary. 
DESCRIPTION=''
# Virtual OS/processor architecture.
ARCH='amd64'
# Allocated memory or RAM (MiB).
MEMORY='2048'
# Limit number of CPU sockets to use.  Value 0 indicates no CPU limit.
CPULIMIT='0'
# CPU weight for a VM. Argument is used in the kernel fair scheduler. The larger the number is, the more CPU time this VM gets.
CPUUNITS='1024'
# The number of cores assigned to the vm/ct. Do not edit - its auto set.
CORES='1'

#----[COMMON_NET_OPTIONS]
# Bridge to attach the network device to.
BRIDGE='vmbr0'
# A common MAC address with the I/G (Individual/Group) bit not set. 
HWADDR=""
# Controls whether this interface’s firewall rules should be used.
FIREWALL='1'
# VLAN tag for this interface (value 0 for none, or VLAN[2-N] to enable).
TAG='0'
# VLAN ids to pass through the interface
TRUNKS=""
# Apply rate limiting to the interface (MB/s). Value "" for unlimited.
RATE=""
# MTU - Maximum transfer unit of the interface.
MTU=""

#----[COMMON_NET_DNS_OPTIONS]
# Nameserver server IP (IPv4 or IPv6) (value "" for none).
NAMESERVER='192.168.1.5'
# Search domain name (local domain)
SEARCHDOMAIN='local'

#----[COMMON_NET_STATIC_OPTIONS]
# IP address (IPv4). Only works with static IP (DHCP=0).
IP='192.168.1.4'
# IP address (IPv6). Only works with static IP (DHCP=0).
IP6=''
# Default gateway for traffic (IPv4). Only works with static IP (DHCP=0).
GW='192.168.1.5'
# Default gateway for traffic (IPv6). Only works with static IP (DHCP=0).
GW6=''

#---- PVE CT
#----[CT_GENERAL_OPTIONS]
# Unprivileged container. '0' to disable, '1' to enable/yes.
CT_UNPRIVILEGED='1'
# Memory swap
CT_SWAP='512'
# OS
CT_OSTYPE='ubuntu'
# Onboot startup
CT_ONBOOT='1'
# Timezone
CT_TIMEZONE='host'
# Root credentials (leave blank for no pwd)
CT_PASSWORD=''
# Virtual OS/processor architecture.
CT_ARCH='amd64'

#----[CT_FEATURES_OPTIONS]
# Allow using fuse file systems in a container.
CT_FUSE='0'
# For unprivileged containers only: Allow the use of the keyctl() system call.
CT_KEYCTL='0'
# Allow mounting file systems of specific types. (Use 'nfs' or 'cifs' or 'nfs;cifs' for both or leave empty "")
CT_MOUNT=''
# Allow nesting. Best used with unprivileged containers with additional id mapping.
CT_NESTING='0'
# A public key for connecting to the root account over SSH (insert path).

#----[CT_ROOTFS_OPTIONS]
# Virtual Disk Size (GB).
CT_SIZE='10'
# Explicitly enable or disable ACL support.
CT_ACL='0'

#----[CT_STARTUP_OPTIONS]
# Startup and shutdown behavior ( '--startup order=1,up=1,down=1' ).
# Order is a non-negative number defining the general startup order. Up=1 means first to start up. Shutdown in done with reverse ordering so down=1 means last to shutdown.
# Up: Startup delay. Defines the interval between this container start and subsequent containers starts. For example, set it to 240 if you want to wait 240 seconds before starting other containers.
# Down: Shutdown timeout. Defines the duration in seconds Proxmox VE should wait for the container to be offline after issuing a shutdown command. By default this value is set to 60, which means that Proxmox VE will issue a shutdown request, wait 60s for the machine to be offline, and if after 60s the machine is still online will notify that the shutdown action failed. 
CT_ORDER='2'
CT_UP='30'
CT_DOWN='60'

#----[CT_NET_OPTIONS]
# Name of the network device as seen from inside the VM/CT.
CT_NAME='eth0'
CT_TYPE='veth'

#----[CT_OTHER]
# OS Version (NOTE: Guacamole will not install on 22.04 - SSL3 errors with Mysql)
CT_OSVERSION='22.04'
# CTID numeric ID of the given container.
CTID='250'

#----[App_UID_GUID]
# App user
APP_USERNAME='home'
# App user group
APP_GRPNAME='homelab'

#----[REPO_PKG_NAME]
# Repo package name
REPO_PKG_NAME='unifi'


#---- Other Files ------------------------------------------------------------------

# Required PVESM Storage Mounts for CT ( new version )
unset pvesm_required_LIST
pvesm_required_LIST=()
while IFS= read -r line
do
  [[ "$line" =~ ^\#.*$ ]] && continue
  pvesm_required_LIST+=( "$line" )
done << EOF
# Example
backup:CT settings backup storage
EOF

#---- Body -------------------------------------------------------------------------

#---- Introduction
source $COMMON_PVE_SRC_DIR/pvesource_ct_intro.sh

#---- Setup PVE CT Variables
# Ubuntu NAS (all)
source $COMMON_PVE_SRC_DIR/pvesource_set_allvmvars.sh

# Check & create required PVE CT subfolders (all)
source $COMMON_DIR/nas/src/nas_subfolder_installer_precheck.sh

#---- Create OS CT
source $COMMON_PVE_SRC_DIR/pvesource_ct_createvm.sh

#---- Pre-Configuring PVE CT
section "Pre-Configure ${HOSTNAME^} ${VM_TYPE^^}"

# Homelab CT unprivileged mapping
if [ "$CT_UNPRIVILEGED" = 1 ]
then
  source $COMMON_PVE_SRC_DIR/pvesource_ct_homelab_ctidmapping.sh
fi

# Create CT Bind Mounts
source $COMMON_PVE_SRC_DIR/pvesource_ct_createbindmounts.sh

#---- Configure New CT OS
source $COMMON_PVE_SRC_DIR/pvesource_ct_ubuntubasics.sh

#---- Create Homelab Group and User
source $COMMON_PVE_SRC_DIR/pvesource_ct_ubuntu_addhomelabuser.sh


#---- UniFi Controller -------------------------------------------------------------

#---- Install UniFi Controller
section "Install UniFi Controller software"

# Start CT
pct_start_waitloop

# UniFi SW
pct push $CTID $SRC_DIR/unifi-controller/unifi-controller_sw.sh /tmp/unifi-controller_sw.sh -perms 755
pct push $CTID $SRC_DIR/unifi-controller/config/unifi-controller_backup.sh /tmp/unifi-controller_backup.sh -perms 755
pct exec $CTID -- bash -c "export REPO_PKG_NAME=$REPO_PKG_NAME APP_USERNAME=$APP_USERNAME APP_GRPNAME=$APP_GRPNAME && /tmp/unifi-controller_sw.sh"

#---- Finish Line ------------------------------------------------------------------
section "Completion Status."

#---- Set display text
unset display_msg1
# Web access URL
display_msg1=( "https://$(pct exec $CTID -- bash -c "hostname | sed 's/ //g'").$(pct exec $CTID -- bash -c "hostname -d | sed 's/ //g'"):8443 (Recommended to use FQDN)" )
if [ -n "${IP}" ] && [ ! "$IP" = 'dhcp' ]
then
  display_msg1+=( "https://$IP:8443" )
elif [ -n "${IP6}" ] && [ ! "$IP6" = 'dhcp' ]
then
  display_msg1+=( "https://$IP6:8443" )
elif [ "$IP" = 'dhcp' ] || [ "$IP6" = 'dhcp' ]
then
  display_msg1+=( "https://$(pct exec $CTID -- bash -c "hostname -I | sed 's/ //g'"):8443 (not static)" )
  display_msg1+=( "UniFi Controller must be set with a static IP address. Set the container with a static IP or if using a non UniFi DHCP server make a DHCP IP reservation (i.e 192.168.1.4). Also add the hostname $(pct exec $CTID -- bash -c "hostname -I | sed 's/ //g'") to your PiHole Local DNS Records." )
fi

msg_box "UniFi Controller installation was a success. Your UniFi Controller application address:

$(printf '%s\n' "${display_msg1[@]}" | indent2)

More information about configuring a UniFi Controller here: https://github.com/ahuacate/homelab"
echo
#-----------------------------------------------------------------------------------