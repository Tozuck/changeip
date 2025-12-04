#!/bin/bash

echo "Enter Additional IPv4 address:"
read IPADDR

if [[ -z "$IPADDR" ]]; then
    echo "No IP entered. Exiting."
    exit 1
fi

# OVH always uses one netplan file
FILE="/etc/netplan/50-cloud-init.yaml"

echo "Using netplan file: $FILE"

###############################################
# 1. Locate the real addresses: block for ens3
#    NOT the DNS nameserver addresses block
###############################################
ADDR_LINE=$(awk '
  $0 ~ /ens3:/        {in_iface=1}
  $0 ~ /nameservers:/ {in_iface=0}
  in_iface && $0 ~ /^[[:space:]]*addresses:/ {print NR}
' "$FILE")

if [[ -z "$ADDR_LINE" ]]; then
    echo "ERROR: Could not locate the correct addresses: block under ens3."
    exit 1
fi

###############################################
# 2. OVH always has a routed IPv6 that looks like:
#      - "2001:xxxx/128"
#    We read indentation from THAT line
###############################################
IPV6_LI_
