#!/usr/bin/env bash
# Install ZooKeeper into the base image.
source "$(dirname "$0")/lib.sh"

if [[ -d $BASE/opt/zookeeper ]]; then echo "ZooKeeper already in base image, skipping."; exit 0; fi

fetch_apache "zookeeper/zookeeper-$ZK_VERSION/apache-zookeeper-$ZK_VERSION-bin.tar.gz"
mkdir -p "$BASE/opt/zookeeper"
tar -xzf "$CACHE/apache-zookeeper-$ZK_VERSION-bin.tar.gz" -C "$BASE/opt/zookeeper" --strip-components=1

cp "$LAB_DIR/conf/zookeeper/zoo.cfg" "$BASE/opt/zookeeper/conf/zoo.cfg"
for i in $(nodes); do echo "server.$i=zk$i:2888:3888" >> "$BASE/opt/zookeeper/conf/zoo.cfg"; done
echo 'SERVER_JVMFLAGS="-Xms256m -Xmx512m"' > "$BASE/opt/zookeeper/conf/java.env"
cp "$LAB_DIR/conf/zookeeper/zookeeper.service" "$BASE/etc/systemd/system/zookeeper.service"

systemd-nspawn -D "$BASE" bash -c '
  useradd -r -d /var/lib/zookeeper -s /usr/sbin/nologin zookeeper
  mkdir -p /var/lib/zookeeper /var/log/zookeeper
  chown -R zookeeper: /var/lib/zookeeper /var/log/zookeeper /opt/zookeeper
  systemctl enable zookeeper'
