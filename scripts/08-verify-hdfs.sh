#!/usr/bin/env bash
# Verify HA state, DataNodes, a cross-node read, and (optionally) failover.
source "$(dirname "$0")/lib.sh"
H=/opt/hadoop/bin/hdfs

sleep 15
echo "nn1: $(hx 1 $H haadmin -getServiceState nn1 2>/dev/null)"
echo "nn2: $(hx 1 $H haadmin -getServiceState nn2 2>/dev/null)"
hx 1 $H dfsadmin -report 2>/dev/null | grep -i "live datanodes"

hx 1 $H dfs -mkdir -p /lab-test
hx 1 $H dfs -put -f /etc/hostname /lab-test/hostname.txt
echo -n "read from zk3: "; hx 3 $H dfs -cat /lab-test/hostname.txt

if [[ ${1:-} == "--failover" ]]; then
  active=nn1; standby=nn2; a=1; s=2
  [[ $(hx 1 $H haadmin -getServiceState nn1 2>/dev/null) == active ]] || { active=nn2; standby=nn1; a=2; s=1; }
  echo "Stopping active NameNode ($active) on zk$a..."
  sc "$a" stop hdfs-namenode
  sleep 15
  echo "$standby is now: $(hx "$s" $H haadmin -getServiceState "$standby" 2>/dev/null)"
  hx "$s" $H dfs -cat /lab-test/hostname.txt
  sc "$a" start hdfs-namenode
fi
