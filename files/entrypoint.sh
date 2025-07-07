#!/bin/bash

# Fix permissions on mounted directories
if [ "$(id -u)" = "0" ]; then
  echo "Setting permissions for mounted volumes..."
  chown -R foundry:foundry /home/foundry/server_files
  chown -R foundry:foundry /home/foundry/persistent_data
  
  # Make sure FEX is properly set up
  if [ ! -d "/home/foundry/.fex-emu/RootFS/Ubuntu_22_04" ]; then
    echo "Setting up FEX RootFS for foundry user..."
    mkdir -p /home/foundry/.fex-emu/RootFS
    cp -R /home/steam/.fex-emu/RootFS/Ubuntu_22_04 /home/foundry/.fex-emu/RootFS/
    chown -R foundry:foundry /home/foundry/.fex-emu
  fi
else
  echo "Warning: Not running as root, permission fixes may fail"
fi

exec "$@"
