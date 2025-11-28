#!/bin/bash

# ==============================================================================
# 1-Click Deployment Script for URL Shortener
# ==============================================================================
# This script automates the entire process of deploying the URL shortener
# application and its Redis database using Docker.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
IMAGE_NAME="url-shortener"
APP_CONTAINER_NAME="url-shortener-app"
REDIS_CONTAINER_NAME="redis-server"
NETWORK_NAME="url-net"


# --- Step 1: Build the Docker Image ---
echo "Building the '${IMAGE_NAME}' Docker image..."
docker build -t ${IMAGE_NAME} .
echo "Image built successfully."
echo

# --- Step 2: Set up the Docker Network ---
# Create a dedicated network if it doesn't already exist.
# This allows the app and redis containers to communicate securely.
echo "Checking for Docker network '${NETWORK_NAME}'..."
if [ -z "$(docker network ls --filter name=^${NETWORK_NAME}$ --format=\"{{ .Name }}\")" ]; then
    echo "Network not found. Creating network..."
    docker network create ${NETWORK_NAME}
    echo "Network '${NETWORK_NAME}' created."
else
    echo "Network '${NETWORK_NAME}' already exists."
fi
echo

# --- Step 3: Stop and Remove Old Containers ---
# This ensures a clean start and avoids port conflicts.
echo "Stopping and removing any old containers..."
docker stop ${APP_CONTAINER_NAME} >/dev/null 2>&1 || true
docker rm ${APP_CONTAINER_NAME} >/dev/null 2>&1 || true
docker stop ${REDIS_CONTAINER_NAME} >/dev/null 2>&1 || true
docker rm ${REDIS_CONTAINER_NAME} >/dev/null 2>&1 || true
echo "Old containers cleared."
echo

# --- Step 4: Start the Redis Container ---
echo "Starting the Redis container '${REDIS_CONTAINER_NAME}'..."
docker run -d \
    --name ${REDIS_CONTAINER_NAME} \
    --network ${NETWORK_NAME} \
    redis
echo "Redis container is running."
echo

# --- Step 5: Start the URL Shortener Application Container ---
echo "Starting the application container '${APP_CONTAINER_NAME}'..."
docker run -d \
    -p 8000:8000 \
    --network ${NETWORK_NAME} \
    -e REDIS_URL=redis://${REDIS_CONTAINER_NAME}:6379/0 \
    --name ${APP_CONTAINER_NAME} \
    ${IMAGE_NAME}
echo "Application container is running."
echo

# --- Deployment Complete ---
