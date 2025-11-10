#!/bin/bash
# =========================================================
# MTProto Proxy Installer / Remover
# Supports Debian/Ubuntu
# =========================================================
set -e

clear
echo "=============================="
echo "     MTProto Proxy Setup"
echo "=============================="
echo
echo "Выберите действие:"
echo "1) Установить MTProto Proxy"
echo "2) Удалить MTProto Proxy"
read -p "Введите номер (1-2): " ACTION

if [ "$ACTION" = "2" ]; then
    echo "=== 🧹 Удаляем MTProto Proxy ==="

    systemctl stop mtprotoproxy 2>/dev/null || true
    systemctl disable mtprotoproxy 2>/dev/null || true
    rm -f /etc/systemd/system/mtprotoproxy.service
    systemctl daemon-reload

    rm -rf /opt/mtprotoproxy
    userdel tgproxy 2>/dev/null || true

    echo
    echo "✅ MTProto Proxy полностью удалён!"
    echo "Файлы и сервис очищены."
    echo
    exit 0
fi

echo
echo "=== 🧰 Обновляем систему и устанавливаем зависимости ==="
apt update -y
apt upgrade -y
apt install -y python3 python3-pip git nano curl openssl sudo
apt install -y python3 python3-pip git nano curl openssl sudo vim-common
apt install -y python3 python3-pip git nano curl openssl sudo xxd

echo "=== 🔐 Устанавливаем библиотеку cryptography ==="
pip3 install --upgrade pip --break-system-packages
pip3 install cryptography --break-system-packages

echo
echo "=========================="
echo " MTProto Proxy Installer"
echo "=========================="
echo
echo "Выберите режим работы MTProto Proxy:"
echo "1) classic  — простой (без маскировки)"
echo "2) secure   — защищённый (без маскировки)"
echo "3) tls      — с маскировкой под HTTPS (рекомендуется)"
read -p "Введите номер (1-3): " MODE_CHOICE

case "$MODE_CHOICE" in
    1) MODE="classic"; TLS_ENABLED=False ;;
    2) MODE="secure"; TLS_ENABLED=False ;;
    3) MODE="tls"; TLS_ENABLED=True ;;
    *) echo "Неверный выбор, по умолчанию — tls"; MODE="tls"; TLS_ENABLED=True ;;
esac

echo
read -p "Введите порт для MTProxy [по умолчанию 443]: " PORT
PORT=${PORT:-443}

if [ "$TLS_ENABLED" = True ]; then
    echo
    read -p "Введите домен для маскировки (по умолчанию www.google.com): " TLS_DOMAIN
    TLS_DOMAIN=${TLS_DOMAIN:-www.google.com}
else
    TLS_DOMAIN=""
fi

echo
echo "Выбран режим: $MODE"
echo "Выбран порт:  $PORT"
if [ "$TLS_ENABLED" = True ]; then
    echo "TLS-домен:    $TLS_DOMAIN"
fi
sleep 1

echo
echo "=== 📦 Клонируем репозиторий MTProto Proxy ==="
rm -rf /opt/mtprotoproxy
git clone -b stable https://github.com/alexbers/mtprotoproxy.git /opt/mtprotoproxy
cd /opt/mtprotoproxy

echo "=== ⚙️ Создаём конфиг config.py ==="

SECRET=$(openssl rand -hex 16)

cat > /opt/mtprotoproxy/config.py <<EOF
PORT = ${PORT}

USERS = {
    "tg": "${SECRET}",
}

MODES = {
    "classic": $( [ "$MODE" = "classic" ] && echo True || echo False ),
    "secure": $( [ "$MODE" = "secure" ] && echo True || echo False ),
    "tls": $( [ "$MODE" = "tls" ] && echo True || echo False )
}

TLS_DOMAIN = "${TLS_DOMAIN}"
EOF

echo "=== 👤 Создаём системного пользователя tgproxy ==="
useradd --no-create-home -s /usr/sbin/nologin tgproxy || true
chown -R tgproxy:tgproxy /opt/mtprotoproxy

echo "=== 🧩 Создаём systemd сервис ==="
cat > /etc/systemd/system/mtprotoproxy.service <<EOF
[Unit]
Description=Async MTProto proxy for Telegram
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/bin/python3 /opt/mtprotoproxy/mtprotoproxy.py
AmbientCapabilities=CAP_NET_BIND_SERVICE
LimitNOFILE=infinity
User=tgproxy
Group=tgproxy
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

echo "=== 🔄 Перезапускаем systemd и включаем сервис ==="
systemctl daemon-reload
systemctl enable mtprotoproxy
systemctl restart mtprotoproxy

SERVER_IP=$(curl -s https://api.ipify.org || hostname -I | awk '{print $1}')

if [ "$MODE" = "tls" ]; then
    if ! command -v xxd &> /dev/null; then
        echo "⚠️  Утилита xxd не найдена, устанавливаем..."
        apt install -y vim-common >/dev/null 2>&1 || apt install -y xxd >/dev/null 2>&1
    fi
    TLS_HEX=$(echo -n "$TLS_DOMAIN" | xxd -p | tr -d '\n')
    FULL_SECRET="ee${SECRET}${TLS_HEX}"
elif [ "$MODE" = "secure" ]; then
    FULL_SECRET="dd${SECRET}"
else
    FULL_SECRET="${SECRET}"
fi

PROXY_LINK="tg://proxy?server=${SERVER_IP}&port=${PORT}&secret=${FULL_SECRET}"

echo "=== 💾 Сохраняем информацию об установке ==="
cat > /opt/mtprotoproxy/install_info.txt <<EOF
MTProto Proxy Installation Info
--------------------------------
IP:        ${SERVER_IP}
PORT:      ${PORT}
SECRET:    ${SECRET}
MODE:      ${MODE}
TLS:       ${TLS_ENABLED}
TLS_DOMAIN:${TLS_DOMAIN}
LINK:      ${PROXY_LINK}
--------------------------------
EOF

echo
echo "=== ✅ MTProto Proxy установлен и запущен! ==="
echo "---------------------------------------------"
echo "🔹 IP:      ${SERVER_IP}"
echo "🔹 PORT:    ${PORT}"
echo "🔹 SECRET:  ${SECRET}"
echo "🔹 MODE:    ${MODE}"
if [ "$TLS_ENABLED" = True ]; then
    echo "🔹 TLS_DOMAIN: ${TLS_DOMAIN}"
fi
echo
echo "👉 Ссылка для Telegram:"
echo "${PROXY_LINK}"
echo "---------------------------------------------"
echo
echo "📋 Проверка статуса:  systemctl status mtprotoproxy"
echo "📜 Логи:              journalctl -u mtprotoproxy -f"
echo "📂 Информация:        /opt/mtprotoproxy/install_info.txt"
echo "⚙️  Конфиг:           /opt/mtprotoproxy/config.py"
echo