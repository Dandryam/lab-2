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

# Запуск сервисов
service knockd start
service fail2ban start
/usr/sbin/sshd -D