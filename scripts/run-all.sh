#!/usr/bin/env bash
# Full build from nothing. Run as root from anywhere.
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
for s in 01-host-network 02-build-base-image 03-install-zookeeper 04-create-containers \
         05-verify-zookeeper 06-install-hdfs 07-init-hdfs 08-verify-hdfs; do
  echo; echo "===== $s ====="
  bash "$D/$s.sh"
done
