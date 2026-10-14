#!/usr/bin/env bash
# Wait for a leader, show each node's role, and do a replication check.
source "$(dirname "$0")/lib.sh"

echo "Waiting for the ensemble to elect a leader..."
for _ in $(seq 1 12); do
  modes=$(for i in $(nodes); do in_c "$i" /opt/zookeeper/bin/zkServer.sh status 2>&1 | grep -o 'Mode: .*' || true; done)
  if grep -q leader <<<"$modes"; then break; fi
  sleep 5
done

for i in $(nodes); do
  echo -n "zk$i: "
  in_c "$i" /opt/zookeeper/bin/zkServer.sh status 2>&1 | grep -o 'Mode: .*' || echo "not running"
done

echo "Replication check: write on zk1, read on zk$N"
in_c 1 /opt/zookeeper/bin/zkCli.sh -server zk1:2181 delete /lab-check >/dev/null 2>&1 || true
in_c 1 /opt/zookeeper/bin/zkCli.sh -server zk1:2181 create /lab-check "replicated" >/dev/null 2>&1
in_c "$N" /opt/zookeeper/bin/zkCli.sh -server "zk$N:2181" get /lab-check 2>&1 | grep -x replicated \
  && echo "OK: value read back from zk$N"
in_c 1 /opt/zookeeper/bin/zkCli.sh -server zk1:2181 delete /lab-check >/dev/null 2>&1 || true
