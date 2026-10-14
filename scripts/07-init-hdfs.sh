#!/usr/bin/env bash
# First-time HA initialisation. ORDER MATTERS:
# JournalNodes -> format nn1 -> start nn1 -> bootstrap nn2 -> start nn2 -> formatZK -> ZKFCs -> DataNodes.
# Services are enabled for boot only at the end; enabling them earlier makes the
# NameNodes crash-loop with "NameNode is not formatted".
source "$(dirname "$0")/lib.sh"
H=/opt/hadoop/bin/hdfs

echo "[1/6] JournalNodes"
for i in 1 2 3; do sc "$i" start hdfs-journalnode; done
for i in 1 2 3; do wait_port "$i" 8485; done

echo "[2/6] Format + start NameNode 1"
if in_c 1 /usr/bin/test -d /var/lib/hadoop-hdfs/nn/current; then
  echo "  nn1 already formatted, skipping format"
else
  hx 1 $H namenode -format -nonInteractive
fi
sc 1 start hdfs-namenode
wait_port 1 8020

echo "[3/6] Bootstrap + start NameNode 2"
if in_c 2 /usr/bin/test -d /var/lib/hadoop-hdfs/nn/current; then
  echo "  nn2 already initialised, skipping bootstrap"
else
  hx 2 $H namenode -bootstrapStandby -nonInteractive
fi
sc 2 start hdfs-namenode
wait_port 2 8020

echo "[4/6] ZooKeeper failover state + ZKFCs"
hx 1 $H zkfc -formatZK -force -nonInteractive
sc 1 start hdfs-zkfc
sc 2 start hdfs-zkfc

echo "[5/6] DataNodes"
for i in 1 2 3; do sc "$i" start hdfs-datanode; done

echo "[6/6] Enable services at boot"
for i in 1 2; do sc "$i" enable hdfs-journalnode hdfs-namenode hdfs-zkfc hdfs-datanode; done
sc 3 enable hdfs-journalnode hdfs-datanode
echo "Done. Next: 08-verify-hdfs.sh"
