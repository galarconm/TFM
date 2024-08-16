#!/bin/bash

# Set the VNC password environment variable
export USER=usuario

# Start VNC server with XFCE desktop environment
vncserver :3 -geometry $RESOLUTION -depth 24

# Start MATE desktop environment
DISPLAY=:3 mate-session &

# Keep the script running to avoid container exit
tail -f /home/usuario/.vnc/*.log
