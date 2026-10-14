# ZooKeeper + HA HDFS on systemd-nspawn (Arch Linux host)

A reproducible, scripted lab that builds a 3-node **Apache ZooKeeper** ensemble and a
**highly available HDFS** cluster (automatic NameNode failover) inside **Debian 12
systemd-nspawn containers** with **OpenJDK 17** — no Docker, no VMs.

## Architecture

```
Arch Linux host
  zkbr0 bridge 10.10.10.1/24 (NAT via systemd-networkd)
   |
   +-- zk1 10.10.10.11  ZooKeeper(myid=1) NameNode(nn1) ZKFC JournalNode DataNode
   +-- zk2 10.10.10.12  ZooKeeper(myid=2) NameNode(nn2) ZKFC JournalNode DataNode
   +-- zk3 10.10.10.13  ZooKeeper(myid=3)               JournalNode DataNode
```

- **ZooKeeper** elects a leader and stores the HDFS failover lock (`/hadoop-ha`).
- **ZKFC** (ZooKeeper Failover Controller) watches each NameNode and triggers failover.
- **JournalNodes** (quorum journal) share the edit log between the two NameNodes.
- Replication factor 3 across the three DataNodes.

| Component | Version |
|---|---|
| Host | Arch Linux |
| Container OS | Debian 12 (bookworm) |
| Java | OpenJDK 17 |
| ZooKeeper | 3.8.x (stable branch) — see `lab.env` |
| Hadoop | 3.5.0 (first release with full JDK 17 support) |

## Prerequisites (host)

```bash
sudo pacman -S --needed debootstrap debian-archive-keyring curl   # systemd-nspawn/machinectl ship with systemd
```
About 6 GB free disk (each container holds its own copy of Hadoop) and ~8 GB RAM recommended.

## Quick start

```bash
git clone https://github.com/<you>/zk-hdfs-nspawn-lab.git
cd zk-hdfs-nspawn-lab
sudo ./scripts/run-all.sh        # or run scripts/01..08 one at a time
```

| Script | What it does |
|---|---|
| `01-host-network.sh` | Creates the `zkbr0` bridge with NAT |
| `02-build-base-image.sh` | `debootstrap` Debian 12 + JDK 17 template |
| `03-install-zookeeper.sh` | Installs and configures ZooKeeper in the template |
| `04-create-containers.sh` | Clones zk1..zk3, static IPs, `myid`, starts + enables them |
| `05-verify-zookeeper.sh` | Waits for a leader, replication check |
| `06-install-hdfs.sh` | Installs Hadoop, config, systemd units |
| `07-init-hdfs.sh` | Ordered HA initialisation (format, bootstrap, formatZK, start) |
| `08-verify-hdfs.sh [--failover]` | HA state, DataNode count, read/write, optional failover test |
| `99-teardown.sh` | Removes everything |

## Verify

```bash
sudo ./scripts/08-verify-hdfs.sh --failover
# NameNode UIs: http://10.10.10.11:9870  and  http://10.10.10.12:9870
```

Expected: one `active` and one `standby` NameNode, `Live datanodes (3)`, a file
written via zk1 readable from zk3, and the standby promoted to active within
seconds when the active NameNode is stopped.

<!-- Add screenshots here: leader election, NameNode UI active/standby, failover -->

## Lessons learned

- **Initialisation order matters.** Enabling the NameNode service before running
  `namenode -format` makes it crash-loop with `NameNode is not formatted`.
  `07-init-hdfs.sh` formats first and enables services last.
- **4 ZooKeeper nodes tolerate only 1 failure — same as 3.** Use odd ensemble sizes.
- **Leadership does not fail back.** A restarted node rejoins as a follower.
- **Fencing:** `shell(/bin/true)` is acceptable here only because the JournalNodes
  block two active writers. Production needs real fencing (e.g. `sshfence`).
- **Static IPs + `/etc/hosts`** are required: ZooKeeper and HDFS identify peers by hostname.

## Troubleshooting

```bash
machinectl list
journalctl -M zk1 -u hdfs-namenode -n 50 --no-pager | grep -v classpath
journalctl -M zk1 -u zookeeper -n 50 --no-pager
```

## Possible extensions

Kafka on the same ensemble, YARN + Spark, Hive Metastore, an ingestion job that
lands data in HDFS, Prometheus/Grafana monitoring.

## License

MIT
