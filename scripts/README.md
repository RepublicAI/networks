# Republic AI - Validator Automation Scripts

A collection of production-ready automation scripts for Republic AI validators.

## Scripts

### full-auto.sh
Complete job automation script that handles the full compute workflow.

**Features:**
- Automatic job submission and result submission
- GPU inference via Docker with 60s timeout
- Thermal protection (75°C → 90s wait, 80°C → 3min, 85°C → 5min)
- Network health check with auto-retry
- Bech32 address bug fix (rai → raivaloper prefix)
- Sequence mismatch protection (15s delay between TXs)

**Usage:**
```bash
# Edit configuration variables at the top of the script
nano full-auto.sh

# Run
chmod +x full-auto.sh
nohup ./full-auto.sh >> ~/full-auto.log 2>&1 &
```

---

### watchdog.sh
Monitors full-auto.sh and automatically restarts it if it crashes.

**Usage:**
```bash
chmod +x watchdog.sh
nohup ./watchdog.sh >> ~/watchdog.log 2>&1 &
```

---

### unjail.sh
Monitors validator jail status every 5 minutes and auto-unjails.

**Usage:**
```bash
chmod +x unjail.sh
nohup ./unjail.sh >> ~/unjail.log 2>&1 &
```

---

### monitor.sh
Real-time dashboard showing node, validator, GPU, and job status.

**Usage:**
```bash
chmod +x monitor.sh
./monitor.sh
```

## Requirements

- Ubuntu 22.04 / 24.04 (or WSL2)
- NVIDIA GPU with CUDA support
- Docker with NVIDIA Container Toolkit
- `jq`, `curl`, `python3`
- `bech32` Python library: `pip install bech32`

## Tested On

- Ubuntu 24.04 LTS + WSL2 (Windows 11)
- NVIDIA RTX 4050 Laptop GPU (6GB)
- Republic AI testnet v0.3.0

## Author

[@erhnysr](https://github.com/erhnysr)
