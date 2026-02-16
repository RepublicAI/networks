# Republic AI Testnet

Welcome to the Republic AI testnet! This guide will help you join the network as a validator.

## Network Information

| Property | Value |
|----------|-------|
| Chain ID | `raitestnet_77701-1` |
| EVM Chain ID | `77701` |
| Bech32 Prefix | `rai` |
| Denom | `arai` (base), `RAI` (display) |
| Decimals | 18 |
| Min Gas Price | `250000000arai` |

## Public Endpoints

| Service | URL |
|---------|-----|
| Cosmos RPC | https://rpc.republicai.io |
| REST API | https://rest.republicai.io |
| Swagger | https://rest.republicai.io/swagger/ |
| gRPC | grpc.republicai.io:443 |
| EVM JSON-RPC | https://evm-rpc.republicai.io |

## Joining the Network

### Prerequisites

- Ubuntu 24.04 LTS
- 4+ CPU cores
- 16GB+ RAM
- 500GB+ SSD
- curl, jq

**Available builds**: `republicd-linux-amd64` (x86_64), `republicd-linux-arm64` (aarch64/Apple Silicon VMs), and `republicd-darwin-arm64` (macOS Apple Silicon). The install scripts below auto-detect your architecture, but if you need a specific build, check the [releases page](https://github.com/RepublicAI/networks/releases).

### Option 1: State Sync (Recommended)

State sync allows you to quickly sync from a recent snapshot instead of syncing from genesis.

```bash
# 1. Install republicd binary (auto-detects latest release)
VERSION=$(curl -s https://api.github.com/repos/RepublicAI/networks/releases/latest | jq -r .tag_name)
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
curl -L "https://github.com/RepublicAI/networks/releases/download/${VERSION}/republicd-linux-${ARCH}" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd

# 2. Initialize node
REPUBLIC_HOME="$HOME/.republic"
republicd init <your-moniker> --chain-id raitestnet_77701-1 --home "$REPUBLIC_HOME"

# 3. Download genesis
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > "$REPUBLIC_HOME/config/genesis.json"

# 4. Configure state sync
SNAP_RPC="https://statesync.republicai.io"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"

# 5. Configure persistent peers
PEERS="cd10f1a4162e3a4fadd6993a24fd5a32b27b8974@52.201.231.127:26656,f13fec7efb7538f517c74435e082c7ee54b4a0ff@3.208.19.30:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"

# 6. Start node
republicd start --home "$REPUBLIC_HOME" --chain-id raitestnet_77701-1
```

### Option 2: Full Sync from Genesis

```bash
# 1. Install republicd binary (auto-detects latest release)
VERSION=$(curl -s https://api.github.com/repos/RepublicAI/networks/releases/latest | jq -r .tag_name)
ARCH=$(uname -m | sed 's/x86_64/amd64/' | sed 's/aarch64/arm64/')
curl -L "https://github.com/RepublicAI/networks/releases/download/${VERSION}/republicd-linux-${ARCH}" -o /tmp/republicd
chmod +x /tmp/republicd
sudo mv /tmp/republicd /usr/local/bin/republicd

# 2. Initialize node
REPUBLIC_HOME="$HOME/.republic"
republicd init <your-moniker> --chain-id raitestnet_77701-1 --home "$REPUBLIC_HOME"

# 3. Download genesis
curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json > "$REPUBLIC_HOME/config/genesis.json"

# 4. Configure persistent peers
PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"

# 5. Start node
republicd start --home "$REPUBLIC_HOME" --chain-id raitestnet_77701-1
```

### Option 3: Docker

Pull the published image (uses latest tag, or pin a specific version):

```bash
docker pull ghcr.io/republicai/republicd:latest
```

Initialize data and fetch genesis:

```bash
REPUBLIC_HOME="$HOME/.republic"
mkdir -p "$REPUBLIC_HOME"

# Initialize (runs as root to create files)
docker run --rm \
  --user 0:0 \
  -v "$REPUBLIC_HOME:/home/republic/.republic" \
  ghcr.io/republicai/republicd:latest \
  init my-node --chain-id raitestnet_77701-1 --home /home/republic/.republic

# Download genesis
sudo curl -s https://raw.githubusercontent.com/RepublicAI/networks/main/testnet/genesis.json -o "$REPUBLIC_HOME/config/genesis.json"
```

Configure state sync (recommended for faster sync):

```bash
SNAP_RPC="https://statesync.republicai.io"
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height)
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000))
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sudo sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" "$REPUBLIC_HOME/config/config.toml"

PEERS="e281dc6e4ebf5e32fb7e6c4a111c06f02a1d4d62@3.92.139.74:26656,cfb2cb90a241f7e1c076a43954f0ee6d42794d04@54.173.6.183:26656,dc254b98cebd6383ed8cf2e766557e3d240100a9@54.227.57.160:26656"
sudo sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$REPUBLIC_HOME/config/config.toml"

# Fix ownership to match container user (UID 1001)
sudo chown -R 1001:1001 "$REPUBLIC_HOME"
```

Run the node:

```bash
docker run -d --name republicd \
  --network host \
  -v "$REPUBLIC_HOME:/home/republic/.republic" \
  ghcr.io/republicai/republicd:latest \
  start --home /home/republic/.republic --chain-id raitestnet_77701-1
```

> **Note**: `--network host` is required for proper P2P connectivity and state sync. Ports 26656, 26657, 1317, 9090, 8545, 8546 will be exposed on the host.

Check logs:

```bash
docker logs -f republicd
```

## Becoming a Validator

Once your node is fully synced, you can create a validator:

```bash
# 1. Create or import a key
republicd keys add <key-name>
# OR import existing key
republicd keys add <key-name> --recover

# 2. Get testnet tokens from faucet (contact team)

# 3. Create validator
republicd tx staking create-validator \
  --amount=1000000000000000000000arai \
  --pubkey=$(republicd comet show-validator) \
  --moniker="<your-moniker>" \
  --chain-id=raitestnet_77701-1 \
  --commission-rate="0.10" \
  --commission-max-rate="0.20" \
  --commission-max-change-rate="0.01" \
  --min-self-delegation="1" \
  --gas=auto \
  --gas-adjustment=1.5 \
  --gas-prices="250000000arai" \
  --from=<key-name>
```

**Note**: Minimum self-delegation is 1 RAI (1000000000000000000 arai).

## Useful Commands

### Check Sync Status
```bash
republicd status | jq '.sync_info'
```

### Check Validator Status
```bash
republicd query staking validator $(republicd keys show <key-name> --bech val -a)
```

### Unjail Validator
```bash
republicd tx slashing unjail --from <key-name> --chain-id raitestnet_77701-1 --gas auto --gas-adjustment 1.5 --gas-prices 250000000arai
```

### Delegate Tokens
```bash
republicd tx staking delegate <validator-address> <amount>arai --from <key-name> --chain-id raitestnet_77701-1 --gas auto --gas-adjustment 1.5 --gas-prices 250000000arai
```

## Systemd Service

Create `/etc/systemd/system/republicd.service`:

```ini
[Unit]
Description=Republic Protocol Node
After=network-online.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
ExecStart=/usr/local/bin/republicd start --home /home/ubuntu/.republic --chain-id raitestnet_77701-1
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable republicd
sudo systemctl start republicd
```

## Support

- GitHub Issues: https://github.com/RepublicAI/networks/issues
- Discord: https://discord.com/invite/therepublic
