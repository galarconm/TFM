#!/bin/bash
#OK
echo 'Updating /etc/hosts file...'
HOSTNAME=$(hostname)
echo "127.0.1.1\t$HOSTNAME" >> /etc/hosts

echo "Starting VNC server at $RESOLUTION..."
vncserver -kill :1 || true
vncserver -geometry $RESOLUTION -depth 24 :1

# Start XFCE4
echo "Starting XFCE4..."
startxfce4 &

# Start Spyder
echo "Starting Spyder..."
export DISPLAY=:1
spyder &

echo "VNC server and Spyder started at $RESOLUTION! ^-^"

echo "Starting tail -f /dev/null to keep the container running..."
tail -f /dev/null
