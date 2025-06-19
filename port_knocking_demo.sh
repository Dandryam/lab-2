# Клиентская машина
# Попытка подключения без knocking (должна быть отклонена)
ssh root@localhost -p 2222

# Выполнение knocking
knock -d 500 -v localhost 7000 8000 9000

# Успешное подключение после knocking (в течение 30 сек)
ssh root@localhost -p 2222