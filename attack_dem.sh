#!/bin/bash

SERVER="localhost"
PORT=2222
USER="appuser"
PASSWORD="password123"

# Функция для цветного вывода
red() { echo -e "\033[0;31m$@\033[0m"; }
green() { echo -e "\033[0;32m$@\033[0m"; }

echo "[1] Попытка подключения без knocking (должна завершиться ошибкой)"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ${USER}@${SERVER} -p ${PORT} 2>/dev/null \
    && red "[!] Ошибка: подключение прошло без knocking!" \
    || green "[+] Ожидаемо: подключение без knocking не удалось"

echo -e "\n[2] Выполнение knocking (последовательность портов: 7000,8000,9000)"
knock -d 300 -v ${SERVER} 7000 8000 9000

echo -e "\n[3] Попытка подключения после knocking (должна быть успешной)"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} -tt 'echo "[+] Успешный вход!"; exit' \
    && green "[+] Успешный вход после knocking" \
    || red "[!] Ошибка: не удалось подключиться после knocking"

echo -e "\n[4] Имитация 3 неудачных попыток входа"
for i in {1..3}; do 
    echo "Попытка $i:"
    sshpass -p "wrongpassword" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
        attacker@${SERVER} -p ${PORT} 2>/dev/null \
        && red "[!] Ошибка: неудачная попытка $i прошла без ошибки" \
        || green "[+] Ожидаемо: попытка $i не удалась"
done

echo -e "\n[5] Проверка статуса fail2ban (должен быть бан)"
docker exec ssh-lab fail2ban-client status sshd

echo -e "\n[6] Попытка подключения после бана (должна быть отклонена)"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} 2>/dev/null \
    && red "[!] Ошибка: удалось подключиться во время бана!" \
    || green "[+] Ожидаемо: подключение во время бана не удалось"

echo -e "\n[7] Ожидание снятия бана (60 секунд)..."
sleep 60

echo -e "\n[8] Повторная попытка подключения (должна быть успешной)"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} -tt 'echo "[+] Успешный вход после снятия бана!"; exit' \
    && green "[+] Успешный вход после снятия бана" \
    || red "[!] Ошибка: не удалось подключиться после снятия бана"
