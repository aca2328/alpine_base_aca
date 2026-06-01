#!/bin/bash
set -e

# Docker login — use DOCKER_PASSWORD env var if set, otherwise prompt
echo "Logging in to Docker Hub..."
if [ -z "$DOCKER_PASSWORD" ]; then
    echo "Please enter your Docker Hub password for aca2328:"
    read -s DOCKER_PASSWORD
    echo
fi
echo "$DOCKER_PASSWORD" | docker login --username aca2328 --password-stdin

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

echo "Multi-architecture Docker image built and pushed successfully!"
