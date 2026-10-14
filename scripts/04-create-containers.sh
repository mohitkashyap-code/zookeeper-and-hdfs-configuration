#!/usr/bin/env bash
# Clone the base image into zk1..zkN, give each a static IP and myid, start them.
source "$(dirname "$0")/lib.sh"

mkdir -p /etc/systemd/nspawn
for i in $(nodes); do
  C=$MACHINES/zk$i
  [[ -d $C ]] || cp -a --reflink=auto "$BASE" "$C"

  echo "zk$i" > "$C/etc/hostname"
  echo "$i"   > "$C/var/lib/zookeeper/myid"
  chown --reference="$C/var/lib/zookeeper" "$C/var/lib/zookeeper/myid"

  cat > "$C/etc/systemd/network/20-host0.network" <<EOF
[Match]
Name=host0

[Network]
Address=$SUBNET_PREFIX.1$i/24
Gateway=$SUBNET_PREFIX.1
EOF

  cat > "/etc/systemd/nspawn/zk$i.nspawn" <<EOF
[Exec]
Boot=yes

[Network]
Bridge=$BRIDGE
EOF
done

for i in $(nodes); do
  machinectl show "zk$i" >/dev/null 2>&1 || machinectl start "zk$i"
  machinectl enable "zk$i" || true
done
machinectl list
