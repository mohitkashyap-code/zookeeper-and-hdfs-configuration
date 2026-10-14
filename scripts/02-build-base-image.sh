#!/usr/bin/env bash
# Debian 12 + OpenJDK 17 rootfs that all nodes are cloned from.
source "$(dirname "$0")/lib.sh"

if [[ -d $BASE ]]; then echo "Base image exists, skipping."; exit 0; fi

debootstrap \
  --include=systemd,dbus,openjdk-17-jre-headless,ca-certificates,iproute2,procps,util-linux \
  "$DEBIAN_SUITE" "$BASE" "$DEBIAN_MIRROR"

# Name resolution between nodes
for i in $(nodes); do echo "$SUBNET_PREFIX.1$i zk$i" >> "$BASE/etc/hosts"; done

systemd-nspawn -D "$BASE" systemctl enable systemd-networkd
