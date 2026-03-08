# Republic AI Validator Node — Ubuntu 24.04 LTS Installation Guide

This guide covers setting up a Republic AI validator node on Ubuntu 24.04 LTS (Noble Numbat). Ubuntu 24.04 is the current LTS release and the recommended OS for new validators.

> For Ubuntu 22.04 setup, see [ubuntu-22.04-installation-guide.md](ubuntu-22.04-installation-guide.md)
> For Windows WSL2 setup, see [wsl2-windows-setup-guide.md](wsl2-windows-setup-guide.md)

## System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| CPU | 4 cores | 8+ cores |
| RAM | 16 GB | 32 GB |
| Disk | 100 GB SSD | 500 GB NVMe |
| OS | Ubuntu 24.04 LTS | Ubuntu 24.04 LTS |
| GPU (optional) | NVIDIA GTX 1080 | NVIDIA RTX 3090+ |

## Step 1: System Preparation
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl wget git jq build-essential unzip lz4
```

> **Note:** Ubuntu 24.04 uses `systemd-resolved` by default. If you experience DNS issues, see the [Troubleshooting](#troubleshooting) section.

## Step 2: Install Republic AI Binary
```bash
# Download latest binary
wget https://github.com/RepublicAI/networks/releases/download/v0.3.0/republicd-linux-amd64 -O republicd
chmod +x republicd
sudo mv republicd /usr/local/bin/

# Verify installation
republicd version
```

Expected output: `0.3.0`

## Step 3: Initialize Node
```bash
# Set your moniker (validator name)
MONIKER="YOUR_MONIKER"

republicd init $MONIKER --chain-id raitestnet_77701-1

# Download genesis file
wget -O ~/.republicd/config/genesis.json \
  https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json

# Download address book
wget -O ~/.republicd/config/addrbook.json \
  https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/addrbook.json
```

## Step 4: Configure Node
```bash
# Set seeds and peers
SEEDS="your-seeds-here"
PEERS="your-peers-here"

sed -i "s/^seeds = .*/seeds = \"$SEEDS\"/" ~/.republicd/config/config.toml
sed -i "s/^persistent_peers = .*/persistent_peers = \"$PEERS\"/" ~/.republicd/config/config.toml

# Set minimum gas price
sed -i 's/minimum-gas-prices = ""/minimum-gas-prices = "1000000000arai"/' ~/.republicd/config/app.toml

# Enable REST API
sed -i '/^\[api\]/,/^\[/ s/^enable = false/enable = true/' ~/.republicd/config/app.toml

# Enable TX indexer
sed -i 's/^indexer = "null"/indexer = "kv"/' ~/.republicd/config/config.toml
```

## Step 5: Configure Custom RPC Port (Optional)

If port 26657 is already in use on your system:
```bash
sed -i 's|laddr = "tcp://127.0.0.1:26657"|laddr = "tcp://127.0.0.1:43657"|' ~/.republicd/config/config.toml
sed -i 's|laddr = "tcp://0.0.0.0:26656"|laddr = "tcp://0.0.0.0:43656"|' ~/.republicd/config/config.toml
```

## Step 6: Create Systemd Service
```bash
sudo tee /etc/systemd/system/republicd.service > /dev/null << SERVICE
[Unit]
Description=Republic AI Node
After=network-online.target
Wants=network-online.target

[Service]
User=$USER
ExecStart=$(which republicd) start --home $HOME/.republicd
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

## Step 7: Monitor Sync Status
```bash
# Check if node is syncing
republicd status --node tcp://localhost:26657 | jq '.sync_info'

# Follow logs
journalctl -u republicd -f --no-hostname -o cat
```

Wait for `catching_up` to show `false` before proceeding.

## Step 8: Create Validator Wallet
```bash
# Create new wallet
republicd keys add wallet --keyring-backend test

# Save the mnemonic phrase securely!
# Fund your wallet before creating validator
```

Check your balance:
```bash
republicd query bank balances YOUR_WALLET_ADDRESS --node tcp://localhost:26657
```

## Step 9: Create Validator
```bash
republicd tx staking create-validator \
  --amount 1000000000000000000arai \
  --pubkey $(republicd tendermint show-validator) \
  --moniker "YOUR_MONIKER" \
  --chain-id raitestnet_77701-1 \
  --commission-rate 0.10 \
  --commission-max-rate 0.20 \
  --commission-max-change-rate 0.01 \
  --min-self-delegation 1 \
  --from wallet \
  --keyring-backend test \
  --node tcp://localhost:26657 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  -y
```

## Step 10: GPU Compute Setup (Optional)

To participate in GPU compute jobs, install Docker with NVIDIA support:
```bash
# Install Docker
sudo apt install -y docker.io
sudo usermod -aG docker $USER

# Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt update && sudo apt install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Verify GPU access in Docker
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

Then start the job sidecar:
```bash
republicd tx computevalidation job-sidecar \
  --from wallet \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --node tcp://localhost:26657 \
  --keyring-backend test \
  --poll-interval 10s \
  --work-dir /var/lib/republic/jobs \
  --yes
```

## Useful Commands
```bash
# Check validator status
republicd query staking validator $(republicd keys show wallet --bech val -a --keyring-backend test) \
  --node tcp://localhost:26657

# Check node status
republicd status --node tcp://localhost:26657 | jq '.sync_info.latest_block_height'

# Unjail validator
republicd tx slashing unjail \
  --from wallet \
  --chain-id raitestnet_77701-1 \
  --gas auto \
  --gas-adjustment 1.5 \
  --gas-prices 1000000000arai \
  --node tcp://localhost:26657 \
  --keyring-backend test \
  -y

# Check balance
republicd query bank balances $(republicd keys show wallet --keyring-backend test -a) \
  --node tcp://localhost:26657
```

## Troubleshooting

### DNS resolution issues on Ubuntu 24.04

Ubuntu 24.04 uses `systemd-resolved` which can cause DNS issues:
```bash
sudo rm /etc/resolv.conf
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
sudo bash -c 'echo "nameserver 1.1.1.1" >> /etc/resolv.conf'
```

### Port already in use

If port 26657 is occupied, use custom ports (see Step 5).

### Node not syncing

Check peer connections:
```bash
republicd status --node tcp://localhost:26657 | jq '.node_info.other.rpc_address'
curl -s localhost:26657/net_info | jq '.result.n_peers'
```

### Validator jailed
```bash
# Check jail status
republicd query staking validator YOUR_VALOPER_ADDRESS --node tcp://localhost:26657 | grep jailed

# Unjail
republicd tx slashing unjail --from wallet --chain-id raitestnet_77701-1 \
  --gas auto --gas-adjustment 1.5 --gas-prices 1000000000arai \
  --node tcp://localhost:26657 --keyring-backend test -y
```

## Related Guides

- [Ubuntu 22.04 Installation Guide](ubuntu-22.04-installation-guide.md)
- [WSL2 Windows Setup Guide](wsl2-windows-setup-guide.md)
- [GPU Compute Jobs Guide](gpu-compute-jobs-guide.md)
- [Compute Provisioning Guide](compute-provisioning-guide.md)

---

*Tested on: Ubuntu 24.04 LTS (Noble Numbat) | Republic AI v0.3.0*
*Author: [@erhnysr](https://github.com/erhnysr)*
