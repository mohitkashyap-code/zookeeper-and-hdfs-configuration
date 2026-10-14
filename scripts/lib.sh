#!/usr/bin/env bash
# Shared helpers. Sourced by every script.
set -euo pipefail

LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck disable=SC1091
source "$LAB_DIR/lab.env"

[[ $EUID -eq 0 ]] || { echo "Run as root (sudo)." >&2; exit 1; }

MACHINES=/var/lib/machines
BASE=$MACHINES/zk-base
nodes() { seq 1 "$N"; }

# Run a command inside container zk<n>:  in_c <n> <abs-path-cmd> [args...]
in_c() { local n=$1; shift; systemd-run -M "zk$n" --wait --pipe --quiet "$@"; }
# systemctl inside container:            sc <n> start hdfs-namenode
sc() { local n=$1; shift; in_c "$n" /usr/bin/systemctl "$@"; }
# Run a command as the hdfs user:        hx <n> /opt/hadoop/bin/hdfs dfs -ls /
hx() { local n=$1; shift; in_c "$n" /usr/sbin/runuser -u hdfs -- "$@"; }

# Wait until a TCP port is listening inside container zk<n>
wait_port() {
  local n=$1 port=$2 out
  for _ in $(seq 1 60); do
    out=$(in_c "$n" /usr/bin/ss -ltn 2>/dev/null || true)
    if grep -q ":$port " <<<"$out"; then return 0; fi
    sleep 2
  done
  echo "Timed out waiting for zk$n:$port" >&2
  return 1
}

# Download an Apache release + checksum into $CACHE and verify it.
# fetch_apache zookeeper/zookeeper-3.8.7/apache-zookeeper-3.8.7-bin.tar.gz
fetch_apache() {
  local rel=$1 f base
  f=$(basename "$rel")
  mkdir -p "$CACHE"
  if [[ ! -f $CACHE/$f ]]; then
    for base in https://downloads.apache.org https://archive.apache.org/dist; do
      if curl -fL "$base/$rel" -o "$CACHE/$f" && curl -fL "$base/$rel.sha512" -o "$CACHE/$f.sha512"; then
        break
      fi
      rm -f "$CACHE/$f" "$CACHE/$f.sha512"
    done
  fi
  (cd "$CACHE" && sha512sum -c "$f.sha512")
}
