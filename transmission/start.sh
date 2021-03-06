#! /bin/bash

# Import template function
. /etc/common/template.sh

# Source our persisted env variables from container startup
. /etc/common/environment-variables.sh

# This script will be called with tun/tap device name as parameter 1, and local IP as parameter 4
# See https://openvpn.net/index.php/open-source/documentation/manuals/65-openvpn-20x-manpage.html (--up cmd)
echo "Updating TRANSMISSION_BIND_ADDRESS_IPV4 to the ip of $1 : $4"
export TRANSMISSION_BIND_ADDRESS_IPV4=$4

echo "Generating transmission settings.json from env variables"
# Ensure TRANSMISSION_HOME, sub folder logs and download dir with label are created
mkdir -p ${TRANSMISSION_HOME}/logs
mkdir -p ${TRANSMISSION_DOWNLOAD_DIR}/${SICKRAGE_LABEL}
template /etc/transmission/settings.json.tmpl > ${TRANSMISSION_HOME}/settings.json

if [ ! -e "/dev/random" ]; then
  # Avoid "Fatal: no entropy gathering module detected" error
  echo "INFO: /dev/random not found - symlink to /dev/urandom"
  ln -s /dev/urandom /dev/random
fi

. /etc/transmission/userSetup.sh

echo "STARTING TRANSMISSION"
exec sudo -u ${RUN_AS} /usr/bin/transmission-daemon -g ${TRANSMISSION_HOME} --logfile ${TRANSMISSION_HOME}/logs/transmission.log &

if [ "${OPENVPN_PROVIDER}" = "PIA" ]
then
    echo "CONFIGURING PORT FORWARDING"
    exec /etc/transmission/updatePort.sh &
else
    echo "NO PORT UPDATER FOR THIS PROVIDER"
fi

echo "Transmission startup script complete."
