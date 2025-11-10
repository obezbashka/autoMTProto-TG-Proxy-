# 🚀 autoMTProto-TG-Proxy

Bash-установщик **Telegram MTProto Proxy** для Ubuntu/Debian.

---

## ⚙️ Возможности

- Установка proxy с выбором режима:
  - **classic** — простой  
  - **secure** — защищённый  
  - **tls** — маскировка под HTTPS  
- Выбор порта и домена  
- Автоматическая генерация Telegram-ссылки  
- Возможность удаления уже установленного прокси  
- Сохранение параметров установки в `/opt/mtprotoproxy/install_info.txt`

---

## 🧩 Подготовка к установке

```bash
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y sudo wget

## Установка
bash <(wget -qO- https://raw.githubusercontent.com/obezbashka/autoMTProto-TG-Proxy-/main/install_mtproxy.sh)
