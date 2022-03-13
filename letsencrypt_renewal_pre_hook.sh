#!/bin/bash

# stop adguard-unbound container
# change the path to where you keep the docker-compose.yml
docker-compose -f /home/ubuntu/docker-adguard-unbound/docker-compose.yml down
