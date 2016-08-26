#!/bin/bash
#
# Объявление переменных
export IPT="iptables"

# Интерфейс который смотрит в интернет
export WAN=eth0
export WAN_IP=188.166.45.40

# Очистка всех цепочек iptables
$IPT -F
$IPT -F -t nat
$IPT -F -t mangle
$IPT -X
$IPT -t nat -X
$IPT -t mangle -X

# Установим политики по умолчанию для трафика, не соответствующего ни одному из правил
$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP

# разрешаем локальный траффик для loopback
$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT

# Разрешаем исходящие соединения самого сервера
$IPT -A OUTPUT -o $WAN -j ACCEPT
# ECHO
$IPT -A INPUT -p icmp -s 91.123.28.119/32 -j ACCEPT
# Состояние ESTABLISHED говорит о том, что это не первый пакет в соединении.
# Пропускать все уже инициированные соединения, а также дочерние от них
$IPT -A INPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# Пропускать новые, а так же уже инициированные и их дочерние соединения
$IPT -A OUTPUT -p all -m state --state ESTABLISHED,RELATED -j ACCEPT
# Разрешить форвардинг для уже инициированных и их дочерних соединений
$IPT -A FORWARD -p all -m state --state ESTABLISHED,RELATED -j ACCEPT

# Включаем фрагментацию пакетов. Необходимо из за разных значений MTU
$IPT -I FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

# Отбрасывать все пакеты, которые не могут быть идентифицированы
# и поэтому не могут иметь определенного статуса.
$IPT -A INPUT -m state --state INVALID -j DROP
$IPT -A FORWARD -m state --state INVALID -j DROP

# Приводит к связыванию системных ресурсов, так что реальный
# обмен данными становится не возможным, обрубаем
$IPT -A INPUT -p tcp ! --syn -m state --state NEW -j DROP
$IPT -A OUTPUT -p tcp ! --syn -m state --state NEW -j DROP

# Открываем порт для SSH
$IPT -A INPUT -i $WAN -p tcp --dport 666 -j ACCEPT
# Открываем порт для DNS
$IPT -A INPUT -i $WAN -p udp --dport 53 -j ACCEPT
# Открываем порт для NTP
$IPT -A INPUT -i $WAN -p udp --dport 123 -j ACCEPT
# Открываем порт для HTTP
$IPT -A INPUT -i $WAN -p tcp --dport 80 -j ACCEPT
# Открываем порт для HTTPS
$IPT -A INPUT -i $WAN -p tcp --dport 443 -j ACCEPT
# Открываем порт для WEBMIN
$IPT -A INPUT -i $WAN -p tcp --dport 10000 -j ACCEPT
# Открываем порт для L2TP/IPSec PSK + OpenVPN
$IPT -A INPUT -i $WAN -p udp --dport 500 -j ACCEPT
$IPT -A INPUT -i $WAN -p tcp --dport 1701 -j ACCEPT
$IPT -A INPUT -i $WAN -p udp --dport 4500 -j ACCEPT
$IPT -A INPUT -i $WAN -p udp --dport 1194 -j ACCEPT
# PostgreSQL
$IPT -A INPUT -i $WAN -p tcp --dport 5432 -j ACCEPT
# Логирование
# Все что не разрешено, но ломится отправим в цепочку undef

# $IPT -N undef_in
# $IPT -N undef_out
# $IPT -N undef_fw
# $IPT -A INPUT -j undef_in
# $IPT -A OUTPUT -j undef_out
# $IPT -A FORWARD -j undef_fw

# Логируем все из undef

# $IPT -A undef_in -j LOG --log-level info --log-prefix "-- IN -- DROP "
# # $IPT -A undef_in -j DROP
# $IPT -A undef_out -j LOG --log-level info --log-prefix "-- OUT -- DROP "
# $IPT -A undef_out -j DROP
# $IPT -A undef_fw -j LOG --log-level info --log-prefix "-- FW -- DROP "
# $IPT -A undef_fw -j DROP

# Записываем правила
/sbin/iptables-save  > /etc/sysconfig/iptables
