#!/bin/bash

echo "Building Foundry FEX Docker image..."
docker build -t foundry-fex:latest -f DockerfileFEX .

echo "Creating necessary directories..."
mkdir -p server
mkdir -p data

echo "Starting container with docker-compose..."
docker-compose up -d

echo "Container started. To view logs, run: docker-compose logs -f"
echo "To stop the container, run: docker-compose down"
