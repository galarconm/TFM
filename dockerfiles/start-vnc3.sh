#!/bin/bash
#OK
echo 'Updating /etc/hosts file...'
HOSTNAME=$(hostname)
echo "127.0.1.1\t$HOSTNAME" >> /etc/hosts

# Create a user for VNC authentication
USER_NAME="vncuser"
USER_PASSWORD="vncpassword"
useradd -m $USER_NAME
echo "$USER_NAME:$USER_PASSWORD" | chpasswd

# Set up VNC server to require authentication
mkdir -p /home/$USER_NAME/.vnc
echo $USER_PASSWORD | vncpasswd -f > /home/$USER_NAME/.vnc/passwd
chown -R $USER_NAME:$USER_NAME /home/$USER_NAME/.vnc
chmod 600 /home/$USER_NAME/.vnc/passwd

# Start the window manager
startxfce4 &

echo "Starting VNC server at $RESOLUTION..."
vncserver -kill :2 || true
su - $USER_NAME -c "vncserver :2 -geometry $RESOLUTION &"

echo "VNC server started at $RESOLUTION! ^-^"

echo "Starting tail -f /dev/null..."
tail -f /dev/null