
#!/bin/bash

echo 'Updating /etc/hosts file...'
HOSTNAME=$(hostname)
echo "127.0.1.1\t$HOSTNAME" >> /etc/hosts

# Start XFCE4
echo "Starting XFCE4..."
startxfce4 &

echo "XFCE4 started! ^-^"

echo "Starting tail -f /dev/null to keep the container running..."
tail -f /dev/null