#!/bin/bash

# This script launches the URL shortener application container and connects it to a Redis container.
# Make sure you have already created a Docker network named 'url-net' and are running a Redis container
# named 'redis-server' on that network.
#
# To create the network: docker network create url-net
# To run Redis: docker run -d --name redis-server --network url-net redis

echo "Starting the URL shortener container..."

docker run \
  # -p 8000:8000: Maps port 8000 on the host to port 8000 in the container.
  -p 8000:8000 \
  \
  # --network url-net: Connects this container to the 'url-net' bridge network.
  # This allows it to communicate with other containers on the same network by their container name.
  --network url-net \
  \
  # -e REDIS_URL=...: Sets the REDIS_URL environment variable inside the container.
  # The Python app uses this URL to connect to the Redis container named 'redis-server'.
  -e REDIS_URL=redis://redis-server:6379/0 \
  \
  # --name url-shortener-app: Assigns a custom name to the container for easy reference.
  --name url-shortener-app \
  \
  # url-shortener: Specifies the Docker image to use for creating the container.
  url-shortener
