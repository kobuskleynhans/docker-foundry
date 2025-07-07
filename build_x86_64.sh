#!/bin/bash
# Build the x86_64 version of the Docker image

# Copy the x86_64 files to their standard locations
cp files/wrapper.x86_64.sh files/wrapper.sh
cp files/start.x86_64.sh files/start.sh
cp files/entrypoint.x86_64.sh files/entrypoint.sh
cp Dockerfile.x86_64 Dockerfile

# Build the Docker image
docker build -t docker-foundry:latest .

echo "Docker image has been built successfully as 'docker-foundry:latest'"
echo "You can run it using the following command:"
echo "docker run --name foundry-server -p 3724:3724/udp -p 27015:27015/udp -v /home/steam/docker-foundry/server:/home/foundry/server_files -v /home/steam/docker-foundry/data:/home/foundry/persistent_data -e TZ=\"Africa/Johannesburg\" -e SERVER_NAME=\"Foundry Docker by RMG\" -e SERVER_PWD=l3tm31n -e PAUSE_SERVER_WHEN_EMPTY=true -e MAX_TRANSFER_RATE=8192 docker-foundry:latest"
