#!/bin/bash

echo "Enter Additional IPv4 address:"
read IPADDR

if [[ -z "$IPADDR" ]]; then
    echo "No IP entered. Exiting."
    exit 1
fi

FILE=$(ls /etc/netplan/*.yaml | head -n 1)

echo "Using netplan file: $FILE"

# Find 'addresses:' only under ens3:, not under nameservers:
ADDR_LINE=$(awk '
  $0 ~ /ens3:/ {in_iface=1}
  $0 ~ /nameservers:/ {in_iface=0}
  in_iface && $0 ~ /^[[:space:]]*addresses:/ {print NR}
' "$FILE")

if [[ -z "$ADDR_LINE" ]]; then
    echo "ERROR: Could not find interface addresses block."
    exit 1
fi

# Get next line to detect indentation
NEXT_LINE=$(sed -n "$((ADDR_LINE+1))p" "$FILE")

if echo "$NEXT_LINE" | grep -q "^[[:space:]]*- "; then
    ITEM_INDENT=$(echo "$NEXT_LINE" | sed -E 's/(^[[:space:]]*- ).*/\1/')
else
    ADDR_INDENT=$(sed -n "${ADDR_LINE}p" "$FILE" | sed -E 's/(^[[:space:]]*).*/\1/')
    ITEM_INDENT="${ADDR_INDENT}  - "
fi

echo "Detected correct indent: '$ITEM_INDENT'"

cp "$FILE" "$FILE.bak"

# Insert IPv4 under the correct addresses block
sed -i "$((ADDR_LINE+1)) i ${ITEM_INDENT}${IPADDR}/32" "$FILE"

echo "Validating YAML..."
if ! netplan try; then
    echo "Invalid YAML — restoring backup."
    mv "$FILE.bak" "$FILE"
    exit 1
fi

rm -f "$FILE.bak"

echo "Applying config..."
netplan apply

echo "SUCCESS! Added $IPADDR/32"
