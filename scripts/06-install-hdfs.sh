#!/usr/bin/env bash
# Install Hadoop into zk1..zk3 (HA HDFS co-located with ZooKeeper). Does not start anything.
source "$(dirname "$0")/lib.sh"

fetch_apache "hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz"

for i in $(nodes); do
  C=$MACHINES/zk$i
  if [[ ! -x $C/opt/hadoop/bin/hdfs ]]; then
    mkdir -p "$C/opt/hadoop"
    tar -xzf "$CACHE/hadoop-$HADOOP_VERSION.tar.gz" -C "$C/opt/hadoop" --strip-components=1
  fi

  in_c "$i" /bin/bash -c '
    id hdfs >/dev/null 2>&1 || useradd -r -m -d /var/lib/hadoop-hdfs -s /usr/sbin/nologin hdfs
    mkdir -p /var/lib/hadoop-hdfs/nn /var/lib/hadoop-hdfs/dn /var/lib/hadoop-hdfs/jn /var/log/hadoop
    chown -R hdfs: /var/lib/hadoop-hdfs /var/log/hadoop'

  D=$C/opt/hadoop/etc/hadoop
  cp "$LAB_DIR"/conf/hdfs/core-site.xml "$LAB_DIR"/conf/hdfs/hdfs-site.xml "$D/"
  if ! grep -q HADOOP_LOG_DIR "$D/hadoop-env.sh"; then
    cat >> "$D/hadoop-env.sh" <<EOF
export JAVA_HOME=$JAVA_HOME_IN_CONTAINER
export HADOOP_LOG_DIR=/var/log/hadoop
export HADOOP_HEAPSIZE_MAX=512m
EOF
  fi
  cp "$LAB_DIR"/conf/hdfs/hdfs-*.service "$C/etc/systemd/system/"
  sc "$i" daemon-reload
done
echo "Hadoop $HADOOP_VERSION installed. Next: 07-init-hdfs.sh"
