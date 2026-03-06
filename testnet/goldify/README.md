# Goldify Republic Tools

This folder contains a custom monitoring script developed by **goldify** to help RepublicAI node operators track their node health.

### Feature: Node Health Checker
The `check_health.sh` script provides a quick summary of:
- System CPU, RAM, and Disk usage.
- Real-time block height from the local RPC.
- Sync status (catching_up).

### How to use:
1. Download the script: `wget https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/goldify/check_health.sh`
2. Make it executable: `chmod +x check_health.sh`
3. Run it: `./check_health.sh`

---
*Contribution for RepublicAI Developer Role*

# 🚀 RepublicAI Node Operations - goldify

This repository contains custom scripts and health reports for the **RepublicAI Testnet (raitestnet_77701-1)**, managed by **goldify**.

## 🛠 Tools & Monitoring

### 1. Node Health Checker (`check_health.sh`)
A lightweight bash script designed to monitor the status of the RepublicAI node and system resources in real-time.

**Features:**
- **System Metrics:** CPU Load, RAM usage, and Disk space availability.
- **Node Status:** Fetches current block height and synchronization status (`catching_up`) via local RPC.
- **Error Handling:** Alerts if the RPC is unreachable or the node process is down.

**How to Execute:**
```bash
chmod +x check_health.sh
./check_health.sh
