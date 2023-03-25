#!/bin/bash

shopt -s expand_aliases
source ~/.bash_aliases

echo "Pulling Images..."
docker-compose pull

echo "Updating Containers..."
docker-compose up --detach

echo "Removing Old Images..."
docker image prune -f
