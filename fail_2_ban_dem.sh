# Клиентская машина
# Имитация 3 неудачных попыток входа
for i in {1..3}; do 
    ssh attacker@localhost -p 2222 -o "UserKnownHostsFile=/dev/null" 
done

# Проверка бана
fail2ban-client status sshd

# Попытка подключения после бана (должна быть отклонена)
ssh root@localhost -p 2222

# Ожидание снятия бана (2 минуты)
sleep 120

# Повторная попытка подключения
ssh root@localhost -p 2222
