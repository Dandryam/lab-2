#!/bin/bash

SERVER="localhost"
PORT=2222
USER="appuser"
PASSWORD="password123"

echo "[1] Попытка подключения без knocking (должна завершиться ошибкой)"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ${USER}@${SERVER} -p ${PORT} \
    || echo -e "\n\033[0;31m[!] Ожидаемая ошибка - порт закрыт\033[0m\n"

echo "[2] Выполнение knocking (последовательность портов: 7000,8000,9000)"
knock -d 300 -v ${SERVER} 7000 8000 9000

echo "[3] Попытка подключения после knocking (должна быть успешной)"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} -tt 'echo -e "\n\033[0;32m[+] Успешный вход!\033[0m"; exit'

echo "[4] Имитация 3 неудачных попыток входа"
for i in {1..3}; do 
    echo "Попытка $i:"
    sshpass -p "wrongpassword" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
        attacker@${SERVER} -p ${PORT}
done

echo "[5] Проверка блокировки fail2ban"
docker exec ssh-lab fail2ban-client status sshd

echo "[6] Попытка подключения после бана (должна быть отклонена)"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} \
    || echo -e "\n\033[0;31m[!] Ожидаемая ошибка - IP заблокирован\033[0m\n"

echo "[7] Ожидание снятия бана (60 секунд)..."
sleep 60

echo "[8] Повторная попытка подключения (должна быть успешной)"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} -tt 'echo -e "\n\033[0;32m[+] Успешный вход после снятия бана!\033[0m"; exit'