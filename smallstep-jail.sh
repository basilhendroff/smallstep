#!/bin/bash
# Build an iocage jail under TrueNAS 12.0 using the current package release of SmallStep
# git clone https://github.com/basilhendroff/truenas-iocage-smallstep

# Check for root privileges
if ! [ $(id -u) = 0 ]; then
   echo "This script must be run with root privileges"
   exit 1
fi
print_msg () {
  echo -e "\e[1;32m"$1"\e[0m"
}

#####
#
# General configuration
#
#####

# Initialize defaults
JAIL_IP=""
JAIL_INTERFACES=""
DEFAULT_GW_IP=""
INTERFACE="vnet0"
VNET="on"
POOL_PATH=""
DATA_PATH=""
JAIL_NAME="smallstep"
DNS_PLUGIN=""
CONFIG_NAME="smallstep-config"

# Check for smallstep-config and set configuration
SCRIPT=$(readlink -f "$0")
SCRIPTPATH=$(dirname "${SCRIPT}")
if ! [ -e "${SCRIPTPATH}"/"${CONFIG_NAME}" ]; then
  echo "${SCRIPTPATH}/${CONFIG_NAME} must exist."
  exit 1
fi
. "${SCRIPTPATH}"/"${CONFIG_NAME}"
INCLUDES_PATH="${SCRIPTPATH}"/includes

JAILS_MOUNT=$(zfs get -H -o value mountpoint $(iocage get -p)/iocage)
RELEASE=$(freebsd-version | cut -d - -f -1)"-RELEASE"

# Check that necessary variables were set by smallstep-config
if [ -z "${JAIL_IP}" ]; then
  echo 'Configuration error: JAIL_IP must be set'
  exit 1
fi
if [ -z "${JAIL_INTERFACES}" ]; then
  echo 'JAIL_INTERFACES not set, defaulting to: vnet0:bridge0'
  JAIL_INTERFACES="vnet0:bridge0"
fi
if [ -z "${DEFAULT_GW_IP}" ]; then
  echo 'Configuration error: DEFAULT_GW_IP must be set'
  exit 1
fi
if [ -z "${POOL_PATH}" ]; then
  POOL_PATH="/mnt/$(iocage get -p)"
  echo 'POOL_PATH defaulting to '$POOL_PATH
fi
# If DATA_PATH wasn't set in smallstep-config, set it
if [ -z "${DATA_PATH}" ]; then
  POOL_PATH="${POOL_PATH%/}"
  DATA_PATH="${POOL_PATH}"/apps/smallstep
fi
if [ "${DATA_PATH}" = "${POOL_PATH}" ]; then
  echo "DATA_PATH must be different from POOL_PATH!"
  exit 1
fi

# Extract IP and netmask, sanity check netmask
IP=$(echo ${JAIL_IP} | cut -f1 -d/)
NETMASK=$(echo ${JAIL_IP} | cut -f2 -d/)
if [ "${NETMASK}" = "${IP}" ]
then
  NETMASK="24"
fi
if [ "${NETMASK}" -lt 8 ] || [ "${NETMASK}" -gt 30 ]
then
  NETMASK="24"
fi

if [ ${DATA_PATH:0:1} != "/" ]; then
  DATA_PATH="/${DATA_PATH}"
fi
DATA_PATH="${DATA_PATH%/}"

# DB_PATH=${DATA_PATH}/assets
DB_PATH=${DATA_PATH}

#####
#
# Jail Creation
#
#####

# List packages to be auto-installed after jail creation
cat <<__EOF__ >/tmp/pkg.json
	{
  "pkgs":[
  "step-certificates"
  ]
}
__EOF__

# Create the jail and install previously listed packages
if ! iocage create --name "${JAIL_NAME}" -p /tmp/pkg.json -r "${RELEASE}" interfaces="${JAIL_INTERFACES}" ip4_addr="${INTERFACE}|${IP}/${NETMASK}" defaultrouter="${DEFAULT_GW_IP}" boot="on" host_hostname="${JAIL_NAME}" vnet="${VNET}"
then
	echo "Failed to create jail"
	exit 1
fi
rm /tmp/pkg.json

#####
#
# Directory Creation and Mounting
#
#####
mkdir -p "${DB_PATH}"
iocage exec "${JAIL_NAME}" mkdir -p /var/db/step_ca
iocage fstab -a "${JAIL_NAME}" "${DB_PATH}"  /var/db/step_ca  nullfs  rw  0  0

iocage exec "${JAIL_NAME}" mkdir -p /mnt/includes
iocage fstab -a "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

# Copy pre-written config files
iocage exec "${JAIL_NAME}" cp /mnt/includes/step_ca /usr/local/etc/rc.d/

iocage exec "${JAIL_NAME}" sysrc step_ca_enable="YES"

# Set up the STEPPATH environmental variable
iocage exec "${JAIL_NAME}" echo "setenv STEPPATH /var/db/step_ca/ca" >> /etc/csh.cshrc

#iocage restart "${JAIL_NAME}"

# Don't need /mnt/includes any more, so unmount it
iocage fstab -r "${JAIL_NAME}" "${INCLUDES_PATH}" /mnt/includes nullfs rw 0 0

echo
print_msg "Ignore comments between the dashed lines above."
echo
print_msg "* The step-ca service runs as root:wheel."
print_msg "* CA assets are stored in ${DB_PATH}/ca"
print_msg "* The password required for the service to start is stored in ${DB_PATH}"
