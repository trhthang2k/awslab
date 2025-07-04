#!/bin/bash
apt update -y
apt install -y docker.io

# Start Docker if it's not already running
systemctl start docker
systemctl enable docker

# Pull image từ Docker Hub
docker pull trhthang/homework:latest

# Chạy container với các biến môi trường cần thiết
docker run -d -p 3000:3000 \
  -e AWS_REGION=\
  -e S3_BUCKET= \
  -e DB_HOST= \
  -e DB_USER= \
  -e DB_PASSWORD=\
  -e DB_NAME= \
  trhthang/homework:latest
