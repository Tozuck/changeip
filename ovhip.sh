#!/bin/bash

# ===============================================
# add-ip.sh - Safely add additional IPv4 /32 to netplan
# Works on OVH, Hetzner, Contabo, DigitalOcean, AWS,
# Vultr, Linode, proxmox VMs, VMware, and any cloud.
# ===============================================

echo "Enter Additional IPv4 address:"
read IPADDR

if [[ -z "$IPADDR" ]]; then
    echo "No IP entered. Exiting."
    exit 1
fi

# Detect netplan file
FILE=$(ls /etc/netplan/*.yaml | head -n 1)

if [[ -z "$FILE" ]]; then
    echo "ERROR: No netplan YAML file found."
    exit 1
fi

echo "Using netplan file: $FILE"

# Locate addresses: block
ADDR_LINE=$(grep -n "^[[:space:]]*addresses:" "$FILE" | head -n 1 | cut -d: -f1)

if [[ -z "$ADDR_LINE" ]]; then
    echo "ERROR: Could not find 'addresses:' block in $FILE"
    exit 1
fi

# Read next line to determine indentation and list style
NEXT_LINE=$(sed -n "$((ADDR_LINE+1))p" "$FILE")

# Inline list style (OVH default)
# Example:
# addresses:
#       - "2001:xxxx"
if echo "$NEXT_LINE" | grep -q "^[[:space:]]*- "; then
    ITEM_INDENT=$(echo "$NEXT_LINE" | sed -E 's/(^[[:space:]]*- ).*/\1/')

# Standard list style:
# addresses:
#   - 1.2.3.4/32
else
    ADDR_INDENT=$(sed -n "${ADDR_LINE}p" "$FILE" | sed -E 's/(^[[:space:]]*).*/\1/')
    ITEM_INDENT="${ADDR_INDENT}  - "
fi

echo "Detected correct list indent: '$ITEM_INDENT'"

# Backup file
cp "$FILE" "$FILE.bak"

# Insert IPv4 /32 right below addresses:
sed -i "$((ADDR_LINE+1)) i ${ITEM_INDENT}${IPADDR}/32" "$FILE"

# Validate YAML before applying
echo "Validating YAML with netplan try..."

if ! netplan try; then
    echo "ERROR: Invalid YAML. Restoring backup."
    mv "$FILE.bak" "$FILE"
    exit 1
fi

# YAML valid — remove backup
rm -f "$FILE.bak"

# Apply configuration
echo "Applying new configuration..."
netplan apply

echo "SUCCESS! Added $IPADDR/32 to $FILE"
exit 0
