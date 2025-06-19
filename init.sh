#!/bin/bash

# Сброс iptables
iptables -F
iptables -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Разрешить локальный трафик и необходимые порты
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A INPUT -p udp --dport 7000 -j ACCEPT
iptables -A INPUT -p udp --dport 8000 -j ACCEPT
iptables -A INPUT -p udp --dport 9000 -j ACCEPT

# защита от spoofing
iptables -A INPUT -s 127.0.0.0/8 -j DROP
iptables -A INPUT -s 10.0.0.0/8 -j DROP
iptables -A INPUT -s 172.16.0.0/12 -j DROP
iptables -A INPUT -s 192.168.0.0/16 -j DROP

# Ограничить rate-limit для knocking портов
iptables -A INPUT -p udp --dport 7000 -m limit --limit 1/min -j ACCEPT
iptables -A INPUT -p udp --dport 7000 -j DROP

# Запуск сервисов
service knockd start
service fail2ban start

# Перегенерация host keys (если отсутствуют)
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Запуск SSH в передний план
/usr/sbin/sshd -D -e
