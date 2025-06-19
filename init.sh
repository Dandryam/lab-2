#!/bin/bash

# Генерация SSH ключей
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    echo "Generating SSH host keys..."
    ssh-keygen -A
fi

# Подготовка логов
touch /var/log/auth.log
chmod 640 /var/log/auth.log
chown syslog:adm /var/log/auth.log

# Запуск rsyslog
service rsyslog start

# Очистка сокета fail2ban
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

# Разрешить установленные соединения
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Rate-limiting для knocking портов
iptables -A INPUT -p udp --dport 7000 -m limit --limit 1/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp --dport 7000 -j DROP
iptables -A INPUT -p udp --dport 8000 -m limit --limit 1/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp --dport 8000 -j DROP
iptables -A INPUT -p udp --dport 9000 -m limit --limit 1/min --limit-burst 3 -j ACCEPT
iptables -A INPUT -p udp --dport 9000 -j DROP

# Запуск служб
service knockd start
service fail2ban start

# Запуск SSH
echo "Starting SSH server..."
exec /usr/sbin/sshd -D -e
