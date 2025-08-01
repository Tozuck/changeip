#!/bin/bash

# Detect default network interface (excluding loopback)
INTERFACE=$(ip route get 1.1.1.1 | awk '{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1); exit}')

# Get the assigned source IP address
SOURCE_IP=$(ip -4 addr show "$INTERFACE" | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1)

# Get the default gateway IP
GATEWAY_IP=$(ip route show default | grep "$INTERFACE" | awk '{print $3}')

if [[ -z "$INTERFACE" || -z "$SOURCE_IP" || -z "$GATEWAY_IP" ]]; then
    echo "[✗] Failed to detect network information."
    exit 1
fi

echo "[+] Detected interface: $INTERFACE"
echo "[+] Detected source IP: $SOURCE_IP"
echo "[+] Detected gateway IP: $GATEWAY_IP"

# Create or overwrite /etc/rc.local
cat <<EOF | sudo tee /etc/rc.local > /dev/null
#!/bin/bash
/sbin/ip route replace default via $GATEWAY_IP dev $INTERFACE src $SOURCE_IP
exit 0
EOF

sudo chmod +x /etc/rc.local

# Create systemd service for rc-local if not exists
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

# Enable and start the rc-local service
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable rc-local
sudo systemctl start rc-local

echo "[✓] rc.local setup complete and service enabled."
