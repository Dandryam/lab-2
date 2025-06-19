#!/bin/bash

# Генерация SSH ключей (если отсутствуют)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

# Подготовка логов
touch /var/log/auth.log
chmod 640 /var/log/auth.log  # Более безопасные права
chown syslog:adm /var/log/auth.log

# Запуск rsyslog для логирования
service rsyslog start

# Очистка сокета fail2ban (если остался с прошлого запуска)
rm -f /var/run/fail2ban/fail2ban.sock

# Сброс iptables
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Разрешить локальный трафик
iptables -A INPUT -i lo -j ACCEPT

# Разрешить уже установленные соединения
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Rate-Limiting для портов knocking (защита от брутфорса последовательностей)
# Разрешаем пакеты на UDP порты 7000,8000,9000, но с ограничением по частоте
iptables -A INPUT -p udp --dport 7000 -m limit --limit 1/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp --dport 7000 -j DROP
iptables -A INPUT -p udp --dport 8000 -m limit --limit 1/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp --dport 8000 -j DROP
iptables -A INPUT -p udp --dport 9000 -m limit --limit 1/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp --dport 9000 -j DROP

# Запуск knockd
service knockd start

# Запуск fail2ban
service fail2ban start

# Запуск SSH-демона в foreground
echo "Starting SSH server..."
exec /usr/sbin/sshd -D -e
