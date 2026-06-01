#!/bin/bash

# Docker login
echo "Logging in to Docker Hub..."
echo "Please enter your Docker Hub password for aca2328:"
read -s DOCKER_PASSWORD
echo

echo $DOCKER_PASSWORD | docker login --username aca2328 --password-stdin

# Set up Docker Buildx
if ! docker buildx inspect mybuilder >/dev/null 2>&1; then
    echo "Creating a new builder instance..."
    docker buildx create --name mybuilder --use
else
    echo "Using existing builder instance..."
    docker buildx use mybuilder
fi

# Enable multi-architecture support
docker buildx inspect --bootstrap

# Build and push the Docker image for multiple architectures
# buildx --push automatically creates and pushes a multi-arch manifest
docker buildx build --platform linux/amd64,linux/arm64 -t aca2328/alpaca:latest --push .

# Check if any command failed
if [ $? -eq 0 ]; then
    echo "Multi-architecture Docker image built, manifest created, and pushed successfully!"
else
    echo "An error occurred during the build or push process."
fi
