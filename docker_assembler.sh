# Сборка образа
docker build -t ssh-security-lab .

# Запуск контейнера
docker run -d --cap-add=NET_ADMIN \
    -p 2222:2222 \
    -p 7000:7000/udp \
    -p 8000:8000/udp \
    -p 9000:9000/udp \
    --name ssh-lab \
    ssh-security-lab