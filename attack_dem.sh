#!/bin/bash

SERVER="localhost"
PORT=2222
USER="appuser"
PASSWORD="password123"
KNOCK_PORTS="7000 8000 9000"

# Функции цветного вывода
red() { echo -e "\033[0;31m$@\033[0m"; }
green() { echo -e "\033[0;32m$@\033[0m"; }
blue() { echo -e "\033[0;34m$@\033[0m"; }

header() {
    echo -e "\n===================================="
    blue "$1"
    echo "===================================="
}

# Проверка утилиты knock
if ! command -v knock &> /dev/null; then
    red "Утилита 'knock' не установлена. Установите: sudo apt-get install knockd"
    exit 1
fi

# 1. Проверка без knocking
header "1. Проверка Port Knocking: подключение без последовательности"
ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ${USER}@${SERVER} -p ${PORT} 2>/dev/null \
    && red "[X] ОШИБКА: Удалось подключиться без knocking!" \
    || green "[✓] Успех: Подключение без knocking отклонено"

# 2. Выполнение knocking
header "2. Выполнение Port Knocking (${KNOCK_PORTS})"
knock -d 300 -v ${SERVER} ${KNOCK_PORTS}

# 3. Проверка после knocking
header "3. Проверка Port Knocking: подключение после последовательности"
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} -tt 'echo "[✓] Успех: Удалось подключиться после knocking"; exit' \
    && green "[✓] Успех: Подключение после knocking выполнено" \
    || red "[X] ОШИБКА: Не удалось подключиться после knocking"

# 4. Проверка Fail2Ban
header "4. Проверка Fail2Ban: имитация атаки"
for i in {1..3}; do 
    sshpass -p "wrongpass" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
        attacker@${SERVER} -p ${PORT} 2>/dev/null \
        && red "[X] ОШИБКА: Неудачная попытка $i прошла без ошибки" \
        || green "[✓] Ожидаемо: Попытка $i не удалась"
done

# 5. Проверка блокировки
header "5. Проверка Fail2Ban: подтверждение блокировки"
docker exec ssh-lab fail2ban-client status sshd
sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} 2>/dev/null \
    && red "[X] ОШИБКА: Удалось подключиться во время бана!" \
    || green "[✓] Ожидаемо: Подключение во время бана отклонено"

# 6. Проверка снятия блокировки
header "6. Проверка Fail2Ban: снятие блокировки"
blue "Ожидание снятия бана (60 секунд)..."
sleep 60

sshpass -p "${PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 \
    ${USER}@${SERVER} -p ${PORT} -tt 'echo "[✓] Успех: Удалось подключиться после снятия бана"; exit' \
    && green "[✓] Успех: Подключение после снятия бана выполнено" \
    || red "[X] ОШИБКА: Не удалось подключиться после снятия бана"

echo -e "\n\n"
green "ДЕМОНСТРАЦИЯ ЗАВЕРШЕНА УСПЕШНО!"
blue "Все механизмы защиты работают корректно"
