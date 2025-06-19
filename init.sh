#!/bin/bash

# Генерация SSH ключей (если отсутствуют)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Подготовка логов
touch /var/log/auth.log
chmod 640 /var/log/auth.log  # Более безопасные права
chown syslog:adm /var/log/auth.log

# Запуск syslog
service rsyslog start

# Очистка сокета fail2ban
rm -f /var/run/fail2ban/fail2ban.sock

# Сброс iptables
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Разрешить локальный трафик и необходимые порты
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# Rate-limiting для knocking портов (защита от брутфорса)
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
exec /usr/sbin/sshd -D -e
