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
  -e AWS_REGION=ap-northeast-2 \
  -e S3_BUCKET=hello-world-user-images \
  -e DB_HOST=hello-world-demo-db.cxm4mamy6vlt.ap-northeast-2.rds.amazonaws.com \
  -e DB_USER=admin \
  -e DB_PASSWORD=demo1234! \
  -e DB_NAME=hello_users_db \
  trhthang/homework:latest
