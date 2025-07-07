#!/bin/bash

# To be able to use the volumes user foundry needs access
sudo -u root chown -R foundry:foundry /home/foundry
sudo -u root chmod 755 /steamcmd/steamcmd.sh
sudo -u root chmod -R 755 /steamcmd

# Ensure Wine has proper permissions
export WINEPREFIX=/home/foundry/.wine
chown -R foundry:foundry $WINEPREFIX

exec "$@"
