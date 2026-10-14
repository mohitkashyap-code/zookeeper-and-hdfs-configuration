#!/usr/bin/env bash
# Remove everything this lab created (containers, images, bridge, caches). DESTROYS ALL DATA.
source "$(dirname "$0")/lib.sh"
read -r -p "This deletes zk1..zk3, zk-base, the $BRIDGE bridge and cached downloads. Type 'yes': " a
[[ $a == yes ]] || { echo "Aborted."; exit 1; }

for i in $(nodes); do machinectl poweroff "zk$i" 2>/dev/null || true; done
sleep 10
for i in $(nodes); do machinectl terminate "zk$i" 2>/dev/null || true; machinectl disable "zk$i" 2>/dev/null || true; done
for m in $(for i in $(nodes); do echo "zk$i"; done) zk-base; do machinectl remove "$m" 2>/dev/null || rm -rf "$MACHINES/$m"; done
for i in $(nodes); do rm -f "/etc/systemd/nspawn/zk$i.nspawn"; done
rm -f "/etc/systemd/network/10-$BRIDGE.netdev" "/etc/systemd/network/10-$BRIDGE.network"
ip link delete "$BRIDGE" 2>/dev/null || true
networkctl reload || true
rm -rf "$CACHE"
echo "Clean. (systemd-networkd and installed packages were left untouched.)"
