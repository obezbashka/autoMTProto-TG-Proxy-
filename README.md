# autoMTProto-TG-Proxy 🚀

Bash-установщик Telegram MTProto Proxy для Ubuntu/Debian.

## Возможности
- Установка proxy с выбором режима:
  - classic (простой)
  - secure (защищённый)
  - tls (маскировка под HTTPS)
- Выбор порта и домена
- Автоматическая генерация Telegram-ссылки
- Возможность удаления прокси
- Сохранение параметров установки в `/opt/mtprotoproxy/install_info.txt`

##Подготовка к установке
apt update
apt upgrade
apt install sudo
apt install wget

## Установка
bash <(wget -qO- https://raw.githubusercontent.com/obezbashka/autoMTProto-TG-Proxy-/main/install_mtproxy.sh)
