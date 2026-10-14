#!/usr/bin/env bash
# Private bridge (zkbr0) with NAT, managed by systemd-networkd.
source "$(dirname "$0")/lib.sh"

cat > "/etc/systemd/network/10-$BRIDGE.netdev" <<EOF
[NetDev]
Name=$BRIDGE
Kind=bridge
EOF

cat > "/etc/systemd/network/10-$BRIDGE.network" <<EOF
[Match]
Name=$BRIDGE

[Network]
Address=$SUBNET_PREFIX.1/24
ConfigureWithoutCarrier=yes
IPMasquerade=ipv4
EOF

systemctl enable --now systemd-networkd
networkctl reload || true
sleep 2
networkctl status "$BRIDGE" --no-pager | head -n 6
