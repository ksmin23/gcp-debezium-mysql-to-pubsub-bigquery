#!/bin/bash

# Define the name for the container to be managed.
CONTAINER_NAME="debezium"

# Grant permissions to the host directory that will be mounted as a Docker volume.
# The docker run command below uses '-v $PWD/config:/debezium/config',
# so we need to set permissions for the '$PWD/config' directory.
chmod 777 $PWD/config
chmod 777 $PWD/data

# 1. Check if a container with the same name already exists (both running and stopped).
if [ -n "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Found an existing container named '${CONTAINER_NAME}'. Removing it..."
    # 2. If the container exists, force remove it (stops the container if it's running).
    docker rm -f ${CONTAINER_NAME} >/dev/null 2>&1
else
    echo "No existing container named '${CONTAINER_NAME}' found."
fi

echo "Starting a new container named '${CONTAINER_NAME}'..."

# 3. Run a new container.
docker run -it --name $CONTAINER_NAME \
  -p 8080:8080 \
  -v $PWD/config:/debezium/config \
  -v $PWD/data:/debezium/data \
  debezium/server:3.0.0.Final