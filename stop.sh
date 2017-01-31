#!/bin/bash

echo "Shutting down Akeneo service"
source .env
export SOURCE_PATH="${WORKING_DIR}"
docker-compose down
echo ""
echo "Done"


