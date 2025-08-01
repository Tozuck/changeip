#!/bin/bash

# کشف اینترفیس اصلی (غیراز lo)
INTERFACE=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')

# کشف آدرس IP اختصاص داده‌شده به اون اینترفیس
SOURCE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)

# کشف گیت‌وی پیش‌فرض
GATEWAY_IP=$(ip route show default | grep "$INTERFACE" | awk '{print $3}')

if [[ -z "$INTERFACE" || -z "$SOURCE_IP" || -z "$GATEWAY_IP" ]]; then
    echo "[✗] خطا در شناسایی اطلاعات شبکه."
    exit 1
fi

echo "[+] Interface: $INTERFACE"
echo "[+] Source IP: $SOURCE_IP"
echo "[+] Gateway IP: $GATEWAY_IP"

# ایجاد یا بازنویسی فایل rc.local
cat <<EOF | sudo tee /etc/rc.local > /dev/null
#!/bin/bash
/sbin/ip route replace default via $GATEWAY_IP dev $INTERFACE src $SOURCE_IP
exit 0
EOF

sudo chmod +x /etc/rc.local

# ساختن فایل سرویس rc-local اگر نبود
cat <<EOF | sudo tee /etc/systemd/system/rc-local.service > /dev/null
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local

[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99

[Install]
WantedBy=multi-user.target
EOF

# فعال‌سازی سرویس
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable rc-local
sudo systemctl start rc-local

echo "[✓] تنظیمات با موفقیت انجام شد و rc.local فعال شد."
