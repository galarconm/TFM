#!/bin/bash
#OK
echo 'Updating /etc/hosts file...'
HOSTNAME=$(hostname)
echo "127.0.1.1\t$HOSTNAME" >> /etc/hosts

# Start the window manager
startxfce4 &

echo "Starting VNC server at $RESOLUTION..."
vncserver -kill :2 || true
vncserver :2 -geometry $RESOLUTION &

echo "VNC server started at $RESOLUTION! ^-^"

echo "Starting tail -f /dev/null..."
tail -f /dev/null