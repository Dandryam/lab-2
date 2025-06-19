#!/bin/bash

# Сборка образа
docker build -t ssh-security-lab .

# Остановка и удаление предыдущего контейнера
docker stop ssh-lab >/dev/null 2>&1
docker rm ssh-lab >/dev/null 2>&1

# Запуск контейнера
docker run -d --cap-add=NET_ADMIN \
    --memory=512m \
    --cpus=1 \
    --security-opt no-new-privileges \
    -p 2222:2222 \
    -p 7000:7000/udp \
    -p 8000:8000/udp \
    -p 9000:9000/udp \
    --name ssh-lab \
    ssh-security-lab

echo "Контейнер 'ssh-lab' запущен. Для демонстрации запустите ./demo.sh"
