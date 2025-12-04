#!/bin/bash

echo "Enter Additional IPv4 address:"
read IPADDR

if [[ -z "$IPADDR" ]]; then
    echo "No IP entered. Exiting."
    exit 1
fi

FILE="/etc/netplan/50-cloud-init.yaml"

echo "Using netplan file: $FILE"

###############################################
# 0. AUTO-REPAIR OVH WRONG INDENTATION
###############################################

# Fix addresses: block indentation (OVH bug)
sed -i 's/^ *addresses:$/      addresses:/' "$FILE"

# Fix IPv6 indentation (OVH bug)
sed -i 's/^ *- "2001:/        - "2001:/' "$FILE"

# Fix nameservers indentation (OVH bug)
sed -i 's/^ *nameservers:$/      nameservers:/' "$FILE"
sed -i 's/^ *addresses:$/        addresses:/' "$FILE"

###############################################
# 1. Locate OVH addresses block
###############################################
ADDR_LINE=$(grep -n "^[[:space:]]*addresses:" "$FILE" | grep -v nameservers | head -n1 | cut -d: -f1)

if [[ -z "$ADDR_LINE" ]]; then
    echo "ERROR: OVH addresses block not found."
    exit 1
fi

###############################################
# 2. Read IPv6 line to get indentation
###############################################
IPV6_LINE=$((ADDR_LINE + 1))
IPV6_CONTENT=$(sed -n "${IPV6_LINE}p" "$FILE")

if ! echo "$IPV6_CONTENT" | grep -q "2001:"; then
    echo "ERROR: IPv6 not found after addresses block."
    exit 1
fi

ITEM_INDENT=$(echo "$IPV6_CONTENT" | sed -E 's/(^[[:space:]]*- ).*/\1/')

echo "Detected OVH indent: '$ITEM_INDENT'"

###############################################
# 3. Backup
###############################################
cp "$FILE" "$FILE.bak"

###############################################
# 4. Insert IPv4 above IPv6
###############################################
sed -i "${IPV6_LINE}i ${ITEM_INDENT}${IPADDR}/32" "$FILE"

###############################################
# 5. Validate YAML
###############################################
echo "Validating YAML..."
if ! netplan try; then
    echo "ERROR: YAML invalid — restoring backup."
    mv "$FILE.bak" "$FILE"
    exit 1
fi

rm -f "$FILE.bak"

###############################################
# 6. Apply
###############################################
echo "Applying configuration..."
netplan apply

echo "SUCCESS! Added $IPADDR/32 to OVH netplan."
