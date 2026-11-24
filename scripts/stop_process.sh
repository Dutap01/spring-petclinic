#!/bin/bash
cd /home/ubuntu/scripts
docker compose down || true
docker rmi -f s4616/spring-petclinic:latest
