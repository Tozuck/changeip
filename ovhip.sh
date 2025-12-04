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
# FIND THE REAL addresses: BLOCK FOR ens3 ONLY
###############################################
ADDR_LINE=$(awk '
  $0 ~ /ens3:/        {in_iface=1}
  $0 ~ /nameservers:/ {in_iface=0}
  in_iface && $0 ~ /^[[:space:]]*addresses:/ {print NR}
' "$FILE")

if [[ -z "$ADDR_LINE" ]]; then
    echo "ERROR: Could not find addresses: under ens3."
    exit 1
fi

###############################################
# DETECT THE IPV6 LINE AND EXTRACT INDENTATION
###############################################
# OVH ALWAYS HAS ONE IPv6 AFTER addresses:
IPV6_LINE=$((ADDR_LINE + 1))
IPV6_CONTENT=$(sed -n "${IPV6_LINE}p" "$FILE")

# If this is not IPv6, search for the first 2001: IPv6 line under ens3
if ! echo "$IPV6_CONTENT" | grep -q "2001:"; then
    IPV6_LINE=$(awk '
      $0 ~ /ens3:/        {in_iface=1}
      $0 ~ /nameservers:/ {in_iface=0}
      in_iface && $0 ~ /2001:/ {print NR; exit}
    ' "$FILE")
    IPV6_CONTENT=$(sed -n "${IPV6_LINE}p" "$FILE")
fi

if [[ -z "$IPV6_LINE" ]]; then
    echo "ERROR: Could not find IPv6 routed line under ens3."
    exit 1
fi

# Extract EXACT indentation from IPv6 list item
ITEM_INDENT=$(echo "$IPV6_CONTENT" | sed -E 's/(^[[:space:]]*- ).*/\1/')

echo "Detected OVH indentation: '$ITEM_INDENT'"

###############################################
# BACKUP BEFORE APPLYING
###############################################
cp "$FILE" "$FILE.bak"

###############################################
# INSERT IPv4 ABOVE THE IPv6 ADDRESS
###############################################
sed -i "${IPV6_LINE}i ${ITEM_INDENT}${IPADDR}/32" "$FILE"

###############################################
# VALIDATE YAML BEFORE APPLYING
###############################################
echo "Validating YAML..."
if ! netplan try; then
    echo "ERROR: Invalid YAML, restoring original file."
    mv "$FILE.bak" "$FILE"
    exit 1
fi

rm -f "$FILE.bak"

###############################################
# APPLY CONFIG
###############################################
echo "Applying OVH network config..."
netplan apply

echo "SUCCESS! Added $IPADDR/32"
